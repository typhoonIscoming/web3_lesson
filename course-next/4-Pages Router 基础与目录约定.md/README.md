## 前言

大家好，欢迎来到 Next.js 系列课程的第四课。这一课我们来聊 Pages Router——老牌、常用、在很多线上项目里还在跑的那套路由。学好它，你读老项目不再犯难；和 App Router 做对比、做迁移也更有把握。

今天围绕四件事展开：目录即路由、全局布局 `_app.tsx`、文档结构 `_document.tsx`，以及导航（`next/router` + `Link`）。不难，但非常实用，我们一个个来。

## 第一部分：Pages Router 基础与目录约定

### 目录即路由与文件命名

先说结论：在 Pages Router 里，“目录就是路由”。

- `pages/` 映射网站的 URL。
- `index.tsx` 就是当前目录的根路径。
- 子目录直接对应子路径。

给你一个直观目录，心里过一遍：

```bash
pages/
├── _app.tsx         // 全局布局
├── _document.tsx    // 自定义HTML文档
├── _error.tsx       // 全局错误处理
├── 404.tsx          // 404页面
├── index.tsx        // 首页
├── about.tsx        // 关于页面
├── posts/
│   ├── index.tsx    // 文章列表
│   └── [slug].tsx   // 文章详情
```

### 全局布局 `_app.tsx`

你可以把 `_app.tsx` 理解成“给所有页面包一层外壳”。导航栏、页脚、全局样式都放这儿。提醒一下：如果在 `_app.tsx` 里用 `getInitialProps`，会关闭自动静态优化（ASO），除非必要，不要随手开。

```tsx
// pages/_app.tsx
import type { AppProps } from 'next/app'
import Link from 'next/link'
import '../styles/globals.css'

export default function MyApp({ Component, pageProps }: AppProps) {
  return (
    <div className="min-h-screen flex flex-col">
      <header className="border-b p-4 flex gap-4">
        <Link href="/">首页</Link>
        <Link href="/about">关于</Link>
        <Link href="/posts">文章</Link>
      </header>
      <main className="flex-1 p-6">
        <Component {...pageProps} />
      </main>
      <footer className="border-t p-4 text-center">© 2025 My Blog</footer>
    </div>
  )
}
```

### 自定义文档 `_document.tsx`

`_document.tsx` 负责最外层的 HTML 文档（`<html>`、`<body>`），只在服务端渲染，不会在浏览器端反复渲染。适合设置 `lang`、预加载资源这些“页面一上来就该有”的东西。

```tsx
// pages/_document.tsx
import { Html, Head, Main, NextScript } from 'next/document'

export default function Document() {
  return (
    <Html lang="zh-CN">
      <Head>
        <meta name="theme-color" content="#ffffff" />
        <link rel="preconnect" href="https://fonts.googleapis.com" />
      </Head>
      <body>
        <Main />
        <NextScript />
      </body>
    </Html>
  )
}
```

### 错误处理页面（`404.tsx` 与 `_error.tsx`）

两件事分别管两种错误：

- `pages/404.tsx`：负责“未找到”，也就是 404。
- `pages/_error.tsx`：兜底其它运行时错误（服务端或客户端）。

```tsx
// pages/404.tsx
export default function NotFound() {
  return <div className="p-8">页面不存在（404）</div>
}

// pages/_error.tsx
export default function ErrorPage({ statusCode }) {
  return <div className="p-8">发生错误，状态码：{statusCode || '未知'}</div>
}
```

### App Router 与 Pages Router 的共存

- 两套 Router 可以并存；遇到相同路径，以 `app/` 优先。
- 布局作用域互不干扰：命中 `app/` 用 `layout.tsx`；命中 `pages/` 用 `_app.tsx`/`_document.tsx`。
- 迁移很简单：新页面放 `app/`，老页面留 `pages/`，逐页替换。

## 第二部分：动态路由与导航（实操）

这一段我们动手做三件事：动态路由、捕获所有/可选路由、页面间导航。

### 1. 动态路由 `[slug]`

文件名用方括号就行：`pages/posts/[slug].tsx`。URL 里的 `slug` 会进到路由参数里，用来渲染内容。

```tsx
// pages/posts/[slug].tsx
import { useRouter } from 'next/router'

export default function PostDetail() {
  const { query } = useRouter()
  const slug = query.slug as string
  return (
    <div className="p-6">
      <h1 className="text-xl font-bold mb-2">正在查看文章：{slug}</h1>
      <p>这里是文章的具体内容...</p>
    </div>
  )
}
```

### 2. 捕获所有与可选路由

如果你想一次性接住“剩下的所有路径”，用 `[...slug]`；允许路径为空，用 `[[...slug]]`。这在文档站、分级分类里很常见。

```tsx
// pages/docs/[...slug].tsx
import { useRouter } from 'next/router'

export default function DocsCatchAll() {
  const { query } = useRouter()
  const segments = (query.slug as string[]) || []
  return (
    <div className="p-6">
      <h1>文档路径</h1>
      <p>{segments.join(' / ') || '根文档'}</p>
    </div>
  )
}
```

### 3. 导航：`Link` 与 `next/router`

Pages Router 里导航用两样：`next/link` 负责无刷新跳转；`next/router` 里的 `useRouter()` + `router.push()` 负责“在逻辑里主动跳”。注意和 App Router 的 `next/navigation` 区分。

```tsx
// pages/index.tsx
import Link from 'next/link'
import { useRouter } from 'next/router'

export default function Home() {
  const router = useRouter()

  const goToRandomPost = () => {
    const ids = ['getting-started', 'advanced-tips']
    const slug = ids[Math.floor(Math.random() * ids.length)]
    router.push(`/posts/${slug}`)
  }

  return (
    <main className="p-8">
      <h1 className="text-2xl font-bold mb-4">首页</h1>
      <div className="flex flex-col gap-2">
        <Link href="/posts/getting-started" className="text-blue-600 hover:underline">Getting Started</Link>
        <Link href="/posts/advanced-tips" className="text-blue-600 hover:underline">Advanced Tips</Link>
        <button onClick={goToRandomPost} className="bg-blue-600 text-white px-3 py-2 rounded w-fit mt-4">
          随机跳转一篇文章
        </button>
      </div>
    </main>
  )
}
```

> 小提醒：`useRouter` 是浏览器端能力，务必在客户端渲染的组件里用。Pages Router 用的是 `next/router`，别和 App Router 的 `next/navigation` 混了。

## 第三部分：嵌套布局（getLayout 模式）

如果你想给某个页面额外包一层“局部布局”，可以用每页的 `Component.getLayout`。它和 `_app.tsx` 搭一块，就能形成简单的嵌套结构。

```tsx
// pages/_app.tsx
import type { AppProps } from 'next/app'

type NextPageWithLayout = AppProps['Component'] & {
  getLayout?: (page: React.ReactElement) => React.ReactNode
}

export default function MyApp({ Component, pageProps }: AppProps) {
  const Page = Component as NextPageWithLayout
  const getLayout = Page.getLayout ?? ((page) => page)
  return getLayout(<Page {...pageProps} />)
}
```

```tsx
// components/MiniLayout.tsx
export default function MiniLayout({ children }: { children: React.ReactNode }) {
  return (
    <div style={{ border: '1px solid #ddd', padding: 12 }}>
      <h2 style={{ marginBottom: 8 }}>局部布局</h2>
      {children}
    </div>
  )
}
```

```tsx
// pages/layout-demo.tsx
import MiniLayout from '../components/MiniLayout'

function LayoutDemo() {
  return <div>这是被局部布局包裹的页面</div>
}

LayoutDemo.getLayout = (page: React.ReactElement) => (
  <MiniLayout>{page}</MiniLayout>
)

export default LayoutDemo
```

> 这块先理解思路，不深挖。更复杂的嵌套、SEO、`<head>` 管理我们放到后面课程。

## 总结与作业

### 快速回顾

- Pages Router 以 `pages/` 定义路由，核心是页面文件，加上 `_app.tsx` 的全局外壳和 `_document.tsx` 的文档结构。
- 和 App Router 的区别很直接：一个以 `app/` 和分段布局为中心，一个以 `pages/` 和 `_app.tsx` 为中心。