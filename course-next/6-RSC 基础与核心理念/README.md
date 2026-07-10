## 前言

哈喽，大家好，欢迎来到 Next.js 系列课程的第6课！今天我们要拆解 App Router 的核心能力：服务器组件（RSC，React Server Components）。一句话概括它的价值——“不需要浏览器 JS 的事交给服务器做，浏览器只负责交互”。这会让首屏更快、JS 更少、边界更清晰。我们会用示例把 RSC 怎么取数、怎么和客户端组件配合、怎么配置缓存，一步步讲清楚。准备好，开干！

## 第一部分：RSC 基础与核心理念

### 1. RSC 是什么与优势

默认情况下，App Router 里的组件就是服务器组件（RSC）。它们在服务器渲染，不把 JS 发到浏览器。所以：

- 可以直接在组件里取数（访问数据库/私密环境变量），不必绕 `getServerSideProps`。
- 前端 JS 体积更小，事件绑定与水合压力更低。
- 能和 `fetch` 的缓存、Streaming SSR 配合，首屏更顺滑。

来个小例子，感受“服务器取数 + 模板拼装”：

```tsx
// app/rsc-demo/page.tsx
// 这是一个 RSC 页面，直接在服务器取数并渲染
export default async function RscDemo() {
  const res = await fetch('https://jsonplaceholder.typicode.com/posts', {
    next: { revalidate: 60 },
  })
  const posts = await res.json()
  return (
    <div className="p-6">
      <h1>最新文章（每 60s 重新验证）</h1>
      <ul>
        {posts.map((p: any) => (
          <li key={p.id}>{p.title}</li>
        ))}
      </ul>
    </div>
  )
}
```

> 演示建议：打开页面后，60 秒内刷新看到相同数据；超过 60 秒再刷新，数据会在后台重新验证后更新。

### 2. RSC Payload（特殊数据格式）

RSC 的渲染结果不是传统 JSON，而是一种专用的“组件载荷”（React Flight）。它以流的形式传输“组件树 + 数据 + 客户端组件引用”，由 React 在浏览器端增量解析与拼装：

- 分块传输，配合 `Suspense`，外层先渲染、慢内容后到。
- 使用引用 ID 复用片段，减少重复与体积。
- 到达客户端组件边界后，由浏览器 JS 接管交互。
- 在浏览器 DevTools 的 Network 面板里，路由切换常能看到 `text/x-component` 的分块响应。

下面用两个页面配合 `Suspense`，看 Streaming 的感觉：

```tsx
import Link from 'next/link'

export default async function A() {
  const res = await fetch('https://jsonplaceholder.typicode.com/posts', { next: { revalidate: 60 } })
  const data = await res.json()
  return (
    <main className="p-8">
      <h1 className="text-2xl font-bold mb-4">A</h1>
      <Link href="/rsc-payload/b" className="underline">前往 B</Link>
      <pre>{JSON.stringify(data, null, 2)}</pre>
    </main>
  )
}
```

```tsx
import { Suspense } from 'react'

export default function B() {
  return (
    <main className="p-8">
      <h1 className="text-2xl font-bold mb-4">B</h1>
      <Suspense fallback={<div>加载中…</div>}>
        <Slow />
      </Suspense>
    </main>
  )
}

async function Slow() {
  const res = await fetch('https://jsonplaceholder.typicode.com/posts', { cache: 'no-store' })
  const data = await res.json()
  return <pre>{JSON.stringify(data, null, 2)}</pre>
}
```

> 观察步骤：从 A 导航到 B，打开 Network 面板，注意到路由切换时的响应是分块传输；页面上会先看到外层框架，`Slow` 内容稍后填充进来，这就是 Streaming 的增量渲染体验。

### 3. 能力与限制

RSC 不支持浏览器端交互（不能用 `useState`/`useEffect`，也不能绑事件），但可以渲染客户端组件并传递可序列化的 props。配合方式很简单：

- RSC 做数据与模板拼装。
- 客户端组件承接交互与副作用。

示例：

```tsx
// components/ClientCounter.tsx
"use client"
import { useState } from 'react'

export default function ClientCounter({ label }: { label: string }) {
  const [n, setN] = useState(0)
  return (
    <button className="px-3 py-2 border rounded" onClick={() => setN(n + 1)}>
      {label}: {n}
    </button>
  )
}
```

```tsx
// app/rsc-to-client/page.tsx
import ClientCounter from '@/components/ClientCounter'

export default async function Page() {
  const label = '点击次数'
  return <ClientCounter label={label} />
}
```

> 小结：取数交给服务器组件，交互交给 `'use client'` 组件。两边通过“可序列化的 props”沟通。

### 4. 可序列化边界与常见坑

RSC 只能向客户端组件传递可序列化的 props。可传 JSON 值、`Date`、`URL` 等；不可传函数、类实例、`Map/Set`、数据库连接等。

正确示例：

```tsx
// components/ClientBox.tsx
"use client"
export default function ClientBox({ label }: { label: string }) {
  return <button className="px-3 py-2 border rounded">{label}</button>
}
```

```tsx
// app/good/page.tsx
import ClientBox from '@/components/ClientBox'

export default async function Good() {
  return <ClientBox label="可序列化字符串" />
}
```

错误示例（不要把函数透传过去）：

```tsx
// app/bad/page.tsx
import ClientBox from '@/components/ClientBox'

export default function Bad() {
  const handler = () => {}
  return (
    <ClientBox onClick={handler as any} />
  )
}
```

> 记住：客户端组件里绑定交互，服务器组件只传数据。

## 第二部分：数据获取与缓存

### 1. `fetch` 缓存与 `revalidate`

这里是实操重点：用 `fetch` 配置缓存与增量静态再生成（ISR），以及实时数据的关闭缓存；顺带看看 `loading.tsx` 的加载占位。

- ISR：用 `next: { revalidate: n }` 配置静态页的后台再生成。

```tsx
// app/(blog)/posts/page.tsx
export default async function PostsPage() {
  const res = await fetch('https://jsonplaceholder.typicode.com/posts', {
    next: { revalidate: 120 },
  })
  const posts = await res.json()
  return (
    <main className="p-8">
      <h1 className="text-2xl font-bold mb-4">文章列表（120s ISR）</h1>
      <ul className="list-disc ml-6">
        {posts.map((p: any) => (
          <li key={p.id}>{p.title}</li>
        ))}
      </ul>
    </main>
  )
}

// app/(blog)/posts/loading.tsx
export default function Loading() {
  return <div className="p-8">加载中…</div>
}
```

> 演示建议：先访问一次，随后在 120 秒内刷新，页面走静态缓存；后台会在合适时间重新生成，过期后再刷新即可看到新数据；`loading.tsx` 在首次生成或慢数据时给出占位体验。

### 2. 关闭缓存与实时数据

- 实时数据：用 `cache: 'no-store'` 每次都拿最新。

```tsx
// app/dashboard/page.tsx
export default async function Dashboard() {
  const res = await fetch('https://jsonplaceholder.typicode.com/posts', {
    cache: 'no-store',
  })
  const metrics = await res.json()
  return (
    <div className="p-6">
      <h1>实时指标（不缓存）</h1>
      <pre>{JSON.stringify(metrics, null, 2)}</pre>
    </div>
  )
}
```

> 提醒：不要把敏感信息泄露到客户端。只在服务器组件或服务端模块中读取机密，传到客户端的内容必须是安全的、必要的。

### 3. 请求头与 Cookie

在 RSC 中用 `headers()` 读取请求头（如 `accept-language`、`user-agent`），用 `cookies()` 读取服务端 Cookie（如登录令牌），用来做页面个性化与鉴权。这些 API 仅在服务器端可用，且不要把敏感值透传到客户端。

```tsx
// app/info/page.tsx
import { headers, cookies } from 'next/headers'

export default async function Info() {
  const h = headers()
  const lang = h.get('accept-language')
  const token = cookies().get('auth_token')?.value
  return (
    <main className="p-8">
      <h1 className="text-2xl font-bold mb-4">请求头与 Cookie</h1>
      <pre>{JSON.stringify({ lang, hasToken: !!token }, null, 2)}</pre>
    </main>
  )
}
```

## 第三部分：客户端组件快速对比

客户端组件适用场景：事件、状态、副作用、DOM 操作、浏览器 API；不能直接访问服务器资源。两者协作：服务器做数据与模板，客户端承接交互。

- 极简对比：

```tsx
// components/ClientPing.tsx
"use client"
import { useState } from 'react'
 
export default function ClientPing() {
  const [on, setOn] = useState(false)
  return (
    <button className="px-3 py-2 border rounded" onClick={() => setOn(!on)}>
      {on ? '已开启' : '已关闭'}
    </button>
  )
}
```
 
```tsx
// app/compare/page.tsx
import ClientPing from '@/components/ClientPing'
 
export default async function Compare() {
  const now = new Date().toISOString()
  return (
    <main className="p-8">
      <p className="mb-2">服务器时间：{now}</p>
      <ClientPing />
    </main>
  )
}
```

- 保护机密：用 `server-only` 声明某模块仅服务器端可导入。如果在客户端组件中导入，将在开发或构建阶段抛错并阻止打包。

```tsx
// lib/secret.ts
import 'server-only'
 
export async function getSecret() {
  return process.env.SECRET_VALUE
}
```
 
```tsx
// app/secure/page.tsx
import { getSecret } from '@/lib/secret'

export default async function Secure() {
  const secret = await getSecret()
  return <pre className="p-8">{secret}</pre>
}
```

```tsx
// components/ClientLeaks.tsx
"use client"
import { getSecret } from '@/lib/secret'

export default function ClientLeaks() {
  return <div>此组件不会正常工作：导入阶段即报错</div>
}
```

> 演示建议：尝试在客户端组件里导入 `getSecret`，你会在构建时报错，这就是安全边界在起作用，防止敏感逻辑被下发到浏览器。

## 总结与作业

- 总结：服务器组件负责“取数与模板”，客户端组件负责“交互与副作用”。把不需要浏览器 JS 的事情交给服务器做，体验会更快更稳。
- 缓存与实时：`revalidate` 管新鲜度（ISR），`no-store` 取实时数据；搭配 `loading.tsx` 与 `Suspense` 体验更丝滑；Streaming 让“先出框架、后填慢内容”成为常态。
- 安全边界：用 `server-only` 保护仅服务器可用的代码，谨慎处理 Cookies 与机密数据，避免泄露到客户端。

这节课就到这里。强烈建议把例子都敲一遍、来回切路由、打开 Network 面板观察 RSC Payload 与分块响应。体感最直观，理解也更牢固。我们下一课见！