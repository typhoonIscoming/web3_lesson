## 前言

哈喽，大家好，欢迎来到 Next.js 系列课程的第七课！这节我们聚焦客户端组件（Client Components）。一句话记忆：服务器组件负责“取数与模板”，客户端组件负责“交互与副作用”。把不需要浏览器 JS 的事情交给服务器做，页面更快、包更小、边界更清晰。

本课目标：掌握 `"use client"` 的使用场景与边界；理解如何在页面中组织“客户端岛屿”；会用动态导入集成第三方库；以及从客户端调用 Server Actions 的端到端提交流程。

学习建议：把交互集中在少量客户端组件里，其余保持为服务器组件；浏览器能做的尽量延后加载，不打断首屏。

## 客户端组件是什么与边界

**关于 `'use client'` 的正确理解**

很多开发者看到 `'use client'` 就会认为：“这个组件只在浏览器端运行”。 **这是完全错误的。**

*   **真正的含义** ：`'use client'` 声明了一个 **边界（Boundary）** 。它告诉 Next.js：“从这个文件开始（包括它导入的所有子组件），进入客户端模块图谱（Client Module Graph）”。
*   **不仅仅是 CSR** ：被标记为 `'use client'` 的组件， **依然会在服务端被执行一次** ，用于生成初始 HTML（SSR）。

- 能力与限制：
  - 能力：`"use client"` 文件可以使用 `useState/useEffect`、绑定事件、访问浏览器 API。
  - 边界：不可直接访问服务器资源（私密环境变量/数据库）；参与水合（Hydration），要谨慎使用。
  - 组合：服务器组件可以渲染客户端组件并传递“可序列化”的 props（字符串、数字、对象等），不能传递函数或类实例。
  - 层级：上层组件已声明 `"use client"` 时，渲染的子组件无需重复声明，但同样不能使用仅服务器可用的 API。

 - 最小示例：点赞按钮
 
   ```tsx
   // components/LikeButton.tsx
   "use client"
   import { useState } from 'react'
   
   export default function LikeButton({ initialCount = 0 }: { initialCount?: number }) {
     const [count, setCount] = useState(initialCount)
     return (
       <button onClick={() => setCount((c) => c + 1)} className="px-3 py-2 border rounded">
         👍 点赞 {count}
       </button>
     )
   }
   ```
 
   ```tsx
   // app/page.tsx（服务器组件）
   import LikeButton from '@/components/LikeButton'
   
   export default async function Home() {
     const initialCount = 3
     return (
       <main className="p-8">
         <h1 className="text-2xl font-bold mb-2">首页（RSC）</h1>
         <p className="mb-4">下面是一个客户端交互按钮：</p>
         <LikeButton initialCount={initialCount} />
       </main>
     )
   }
   ```
 
- 层级示例：父子组件
  - 父组件声明 `"use client"`，子组件无需重复声明即可拥有交互能力。
  - 服务器页面引用父组件，形成完整调用栈：页面（RSC）→ 客户端父组件 → 客户端子组件。

  ```tsx
  // components/ClientIsland.tsx（父组件，声明 'use client'）
  "use client"
  import Child from './Child'

  export default function ClientIsland() {
    return <Child />
  }
  ```

  ```tsx
  // components/Child.tsx（子组件，无需重复 'use client'）
  import { useState } from 'react'

  export default function Child() {
    const [count, setCount] = useState(0)
    return <button onClick={() => setCount(count + 1)}>子组件计数 {count}</button>
  }
  ```

  ```tsx
  // app/(demo)/client-hierarchy/page.tsx（服务器组件，引用父组件以完成调用栈）
  import ClientIsland from '../../components/ClientIsland'

  export default function ClientHierarchyDemo() {
    return (
      <main className="p-8">
        <h1 className="text-2xl font-bold mb-2">客户端层级示例</h1>
        <ClientIsland />
      </main>
    )
  }
  ```

讲解提示：把交互放到小组件里，加上 `"use client"` 就能使用状态和事件。页面本身保持为服务器组件，性能更好，首屏更稳。

## 交互与第三方库集成

- 场景说明：
  - 依赖浏览器 API 的库（如 Chart.js）应在客户端使用；必要时用动态导入禁用 SSR。
  - 注意：Next.js 16 中，`next/dynamic` 的 `{ ssr:false }` 需要放在客户端组件里，否则服务器组件会报错。

- 客户端图表示例：
  - 在客户端组件中通过 `import("chart.js/auto")` 初始化并渲染图表；页面引用时作为客户端“岛屿”。
  - 安装提醒：先执行 `npm install chart.js`。

  ```tsx
  // components/ChartClient.tsx
  "use client"
  import { useEffect, useRef } from "react"

  export default function ChartClient() {
    const canvasRef = useRef<HTMLCanvasElement | null>(null)

    useEffect(() => {
      let chart: any
      async function render() {
        const { Chart } = await import("chart.js/auto")
        const ctx = canvasRef.current!.getContext("2d")!
        chart = new Chart(ctx, {
          type: "bar",
          data: {
            labels: ["A", "B", "C"],
            datasets: [
              { label: "示例数据", data: [3, 5, 2], backgroundColor: "#60a5fa" },
            ],
          },
        })
      }
      render()
      return () => {
        if (chart) chart.destroy()
      }
    }, [])

    return <canvas ref={canvasRef} width={300} height={160} />
  }
  ```

- 客户端包装 + 动态导入（禁用 SSR）：
  - 在 `components/ClientChartLazy.tsx` 中使用 `dynamic(() => import('@/components/ChartClient'), { ssr:false, loading })`。
  - 服务器页面 `app/(demo)/client-demo/page.tsx` 引用该包装组件，避免在 RSC 中直接使用 `dynamic`。

  ```tsx
  // components/ClientChartLazy.tsx（客户端包装：在客户端使用 dynamic 禁用 SSR）
  "use client"
  import dynamic from 'next/dynamic'

  const ChartLazy = dynamic(() => import('@/components/ChartClient'), {
    ssr: false,
    loading: () => <div className="p-4">图表加载中…</div>,
  })

  export default function ClientChartLazy() {
    return <ChartLazy />
  }
  ```

  ```tsx
  // app/(demo)/client-demo/page.tsx（服务器组件）
  import ClientChartLazy from '@/components/ClientChartLazy'

  export default function ClientDemo() {
    return (
      <main className="p-8">
        <h1 className="text-2xl font-bold mb-2">客户端组件示例</h1>
        <p className="mb-4">这个图表组件在客户端渲染，避免了不必要的 SSR 负担。</p>
        <ClientChartLazy />
      </main>
    )
  }
  ```

- 第三方脚本加载：
  - 使用 `next/script` 并设置合适策略（如 `lazyOnload`），推迟非关键脚本加载，降低首屏压力。

  ```tsx
  // components/ThirdPartyClient.tsx
  "use client"
  import Script from 'next/script'

  export default function ThirdPartyClient() {
    return (
      <div>
        <Script src="https://example.com/sdk.js" strategy="lazyOnload" />
        <div id="widget" />
      </div>
    )
  }
  ```

- 代码体积对比：
  - 场景 A（基线）：静态引入图表组件，观察首次加载的 JS 总量。
  - 场景 B（优化）：客户端包装 + `dynamic` 禁用 SSR，对比 Network/Coverage 面板的数据与体验。

  ```tsx
  // app/(demo)/client-demo/page.tsx（静态引入示例）
  import ChartClient from '../../components/ChartClient'

  export default function ClientDemo() {
    return (
      <main className="p-8">
        <h1 className="text-2xl font-bold mb-2">客户端组件示例</h1>
        <ChartClient />
      </main>
    )
  }
  ```

实用建议：只在需要交互的组件里使用 `"use client"`；对较重的交互组件使用 `dynamic` 并提供 `loading` 占位；精准引入库、避免整库引入；将复杂计算放到服务器组件或 API Route。

## 用 `client-only` 标记仅客户端模块

- 适用场景：模块内部依赖浏览器能力或第三方浏览器 SDK，不应在服务器端导入。
- 用法与注意：在模块顶部 `import 'client-only'`；这是模块级限制，不替代组件文件中的 `"use client"`。
- 示例与验证：
  - 在客户端组件中使用仅客户端模块，浏览器可见内容正常。
  - 在服务器组件中导入该模块，开发/构建阶段会抛错，阻止 SSR 崩溃。

  ```ts
  // lib/client-widget.ts（仅客户端模块）
  import 'client-only'

  export function showNotice(message: string) {
    const div = document.createElement('div')
    div.textContent = message
    div.style.cssText = 'position:fixed;right:16px;bottom:16px;background:#111;color:#fff;padding:8px 12px;border-radius:6px'
    document.body.appendChild(div)
    setTimeout(() => div.remove(), 2000)
  }
  ```

  ```tsx
  // components/ClientWidgetDemo.tsx（客户端组件中使用）
  "use client"
  import { useEffect } from 'react'
  import { showNotice } from '@/lib/client-widget'

  export default function ClientWidgetDemo() {
    useEffect(() => {
      showNotice('仅客户端模块已加载')
    }, [])
    return <button className="px-3 py-2 border rounded">触发客户端提示</button>
  }
  ```

  ```tsx
  // app/(demo)/server-import/page.tsx（服务器组件，误用示例）
  import { showNotice } from '@/lib/client-widget'

  export default function ServerImportDemo() {

      // 下面这行如果取消注释，会在构建时报错，因为被导入的模块声明了 client-only
      // showNotice('服务器组件中触发客户端提示')

      return <div className="p-8">服务器页面（不要在此导入仅客户端模块）</div>
  }
  ```

## 从客户端调用服务器函数（Server Functions）

- 概念与注意（参考 `course7/脚本_gpt5.md:278-286`）：
  - 定义：通过 `"use server"` 声明的服务器端函数，表单或客户端事件可直接调用，安全访问服务器资源与执行业务逻辑。
  - 要求：必须是 `async` 并返回 `Promise`；只能在服务器端定义；表单直连时会自动接收 `FormData`。

- 使用场景：安全访问数据库/私密 API；数据变更（CRUD）；表单直连提交；缓存精准刷新；文件上传；触发后台任务。

- 文件级 `'use server'`：
  - 在 `app/comments/actions.ts` 顶部添加 `"use server"`，该文件导出的方法均为服务器函数；示例接收 `FormData` 并调用 `revalidateTag('comments')` 刷新缓存。

  ```ts
  // app/comments/actions.ts
  // 文件级声明：放在单独文件顶部，标记该文件所有导出为服务器函数
  'use server'
  import { revalidateTag } from 'next/cache'

  export async function addComment(formData: FormData) {
    // 用于 <form action={addComment}> 或客户端事件传入的 FormData
    // Server Action 接收 FormData（表单提交时自动注入），底层以 POST 方式调用
    const content = String(formData.get('content') || '')
    if (!content.trim()) return
    // 变更后精准刷新带有 'comments' 标签的数据
    revalidateTag('comments')
  }
  ```

- 函数内 `'use server'`：
  - 在函数体顶部声明，仅把该函数标记为服务器函数，便于与同文件的普通导出区分。

  ```ts
  // app/comments/actions-inline.ts（函数内声明示例）
  import { revalidateTag } from 'next/cache'

  export async function addCommentInline(formData: FormData) {
    // 在函数体顶部声明，仅把该函数标记为服务器函数
    'use server'
    const content = String(formData.get('content') || '')
    if (!content.trim()) return
    // 刷新评论列表的缓存
    revalidateTag('comments')
  }
  ```

- 表单直连调用：
  - `<form action={addComment}>` 即使 JS 未加载也能提交；提交时自动将输入项打包成 `FormData` 并传入。

  ```tsx
  // app/comments/page.tsx（服务器组件，表单直连 Server Action）
  import { addComment } from '@/app/comments/actions'

  export default function CommentsPage() {
    return (
      // 表单直连 Server Action：即使 JS 未加载也能提交
      // 提交时会自动把输入项打包成 FormData 并传入 addComment
      <form action={addComment} className="p-8 flex gap-2">
        <input name="content" placeholder="输入评论" className="px-3 py-2 border rounded flex-1" />
        <button className="px-3 py-2 border rounded">提交</button>
      </form>
    )
  }
  ```

- 客户端事件调用：
  - 在客户端 `onSubmit` 中手动构造 `FormData`，用 `useTransition` 展示提交中状态，不阻塞输入；成功后清空输入框。

  ```tsx
  // components/CommentClientForm.tsx（客户端组件，用事件/副作用调用 Server Action）
  "use client"
  import { useTransition, useState } from 'react'
  import { addComment } from '@/app/comments/actions'

  export default function CommentClientForm() {
    const [content, setContent] = useState('')
    const [pending, startTransition] = useTransition()
    return (
      <form
        onSubmit={(e) => {
          e.preventDefault()
          // 在客户端事件中手动构造 FormData 并调用 Server Action
          // 使用 useTransition 展示“提交中”状态，不阻塞输入
          const fd = new FormData()
          fd.append('content', content)
          startTransition(async () => {
            await addComment(fd)
            // 提交成功后清空输入框
            setContent('')
          })
        }}
        className="p-8 flex gap-2"
      >
        <input
          value={content}
          onChange={(e) => setContent(e.target.value)}
          placeholder="输入评论"
          className="px-3 py-2 border rounded flex-1"
        />
        <button disabled={pending} className="px-3 py-2 border rounded disabled:opacity-60">
          {pending ? '提交中…' : '提交'}
        </button>
      </form>
    )
  }
  ```

- 演示页面：
  - 服务器页面渲染客户端表单，形成“服务器页面 → 客户端组件 → Server Action”的完整链路。

  ```tsx
  // app/(demo)/client-actions/page.tsx（服务器组件，渲染客户端表单）
  import CommentClientForm from '@/components/CommentClientForm'

  export default function ClientActionsDemo() {
    return (
      <main className="p-8">
        <h1 className="text-2xl font-bold mb-2">客户端调用 Server Actions</h1>
        <CommentClientForm />
      </main>
    )
  }
  ```

## 总结与作业

- 总结：
  - 客户端组件适合做交互与副作用，范围要小；把取数与模板拼装留在服务器。
  - 与 RSC 协作时，用可序列化 props 传递数据；动态导入可延后加载、配合占位提升体验。
  - 从客户端调用 Server Actions 时，选择表单直连或事件调用，变更后用 `revalidateTag/revalidatePath` 精准刷新。

- 建议练习：
  - 把点赞按钮扩展为“收藏/取消收藏”，体会状态管理与样式切换。
  - 将图表从静态引入改为客户端包装 + 动态导入，对比 Network/Coverage 的差异。
  - 为评论模块加上最简单的校验与提示，提交后刷新列表缓存。
  - 尝试把仅客户端模块误用在服务器组件中，观察构建时的报错，理解安全边界。

提示：如果项目未配置路径别名 `@`，请将示例中的 `@/components/...` 改为相对路径；需要的话可在 `tsconfig.json` 中设置 `baseUrl/paths` 来统一管理。