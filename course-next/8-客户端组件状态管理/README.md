# 客户端组件状态管理

## 前言

欢迎来到 Next.js 实战课程的第八课！今天我们要攻克一个让很多 React 老手都容易“翻车”的难点——**状态管理**。

在传统的 React SPA（单页应用）开发中，我们习惯了遇事不决就 `useState`，或者把所有数据都塞进 Redux/Context 里。但在 Next.js 的服务端渲染（SSR）架构下，如果你还照搬这套逻辑，不仅会丢掉 SSR 的性能优势，还可能导致代码难以维护。

本节课的目标是帮你建立一套适配 Next.js 的**“状态观”**。记住这个优先级原则：

1.  **首选 URL**：凡是值得分享、收藏、刷新的状态（搜索、分页、Tab），统统放 URL 里。
2.  **次选 Local**：UI 的临时交互（弹窗、折叠），用组件内的 `useState`，并尽量下沉。
3.  **最后 Global**：只有跨页面共享的数据（用户 Session、主题），才用 Context 或 Zustand。

---

## Part 1: URL 作为状态源（核心必考题）

这部分是 Next.js 开发的分水岭。新手喜欢用 `useState` 做搜索筛选，而高手懂得用 `URL` 驱动 UI。

### 1.1 为什么不用 useState？
想象一下，你写了一个商品列表页，用 `useState` 存了搜索词 `query`。
- **场景一**：用户搜了 "React"，觉得不错，复制链接发给同事。同事打开链接，发现是空的（因为 `useState` 在刷新后重置了）。
- **场景二**：用户在第 5 页，不小心刷新了浏览器，瞬间回到了第 1 页。

**结论**：凡是决定“页面长什么样”的核心状态，都应该同步到 URL 上。

### 1.2 实战：URL 驱动的搜索栏
我们利用 Next.js 的 `useSearchParams`、`usePathname` 和 `useRouter` 来实现。

```tsx
// components/SearchBar.tsx
"use client"
import { useSearchParams, useRouter, usePathname } from 'next/navigation'
import { useDebouncedCallback } from 'use-debounce' // 强烈建议防抖

export default function SearchBar() {
  const searchParams = useSearchParams()
  const pathname = usePathname()
  const { replace } = useRouter()

  // 核心逻辑：修改 URL 参数，而不是修改本地 State
  const handleSearch = useDebouncedCallback((term: string) => {
    const params = new URLSearchParams(searchParams)
    if (term) {
      params.set('query', term)
    } else {
      params.delete('query')
    }
    
    // replace vs push:
    // 筛选/搜索用 replace（替换当前历史，后退不麻烦）
    // 分页/跳转用 push（保留历史，方便后退）
    replace(`${pathname}?${params.toString()}`)
  }, 300)

  return (
    <input
      // 初始值从 URL 拿，确保刷新后数据还在
      defaultValue={searchParams.get('query')?.toString()}
      onChange={(e) => handleSearch(e.target.value)}
      className="border p-2 rounded"
      placeholder="搜索..."
    />
  )
}
```

### 1.3 服务端如何响应？
这是 URL 状态管理最爽的地方：**服务端组件可以直接读取 URL 参数并获取数据**，无需等待客户端加载 JS。

```tsx
// app/products/page.tsx
// Server Component
export default async function ProductsPage({
  searchParams,
}: {
  // Next.js 15+ 中 searchParams 是 Promise
  searchParams: Promise<{ query?: string; page?: string }>
}) {
  const { query = '', page = '1' } = await searchParams
  
  // 直接在服务端请求数据，SEO 友好，无 Loading 闪烁
  const products = await fetchProducts(query, Number(page))

  return (
    <main>
      <SearchBar />
      <ProductList data={products} />
    </main>
  )
}
```

---

## Part 2: 局部状态与组合模式

很多同学刚转 Next.js 时，为了省事，直接在 `page.tsx` 顶部加 `"use client"`，结果把整个页面都变成了客户端渲染，丧失了 Server Component 的优势。

### 2.1 错误示范：一锅炖
```tsx
// app/page.tsx
"use client" // ❌ 整个页面变成客户端组件
import Header from './Header'
import HeavyChart from './HeavyChart' // 假设这是个很大的图表组件

export default function Page() {
  const [count, setCount] = useState(0) // 只是为了一个小小的计数器
  
  return (
    <div>
      <Header />
      <HeavyChart /> {/* 计数器更新时，这个重型组件也会被迫重渲染！ */}
      <button onClick={() => setCount(c => c + 1)}>{count}</button>
    </div>
  )
}
```

### 2.2 正确示范：状态下沉（State Colocation）
我们将需要交互的部分（计数器）剥离出来，单独封装成一个小的客户端组件。

```tsx
// components/Counter.tsx
"use client" // ✅ 只有这个小组件是客户端的
import { useState } from 'react'

export default function Counter() {
  const [count, setCount] = useState(0)
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>
}
```

```tsx
// app/page.tsx
// ✅ 依然是 Server Component
import Counter from '@/components/Counter'
import Header from '@/components/Header'
import HeavyChart from '@/components/HeavyChart'

export default function Page() {
  return (
    <div>
      <Header />
      <HeavyChart /> {/* 计数器怎么变，都跟我没关系，我只渲染一次 */}
      <Counter />
    </div>
  )
}
```

**原则**：保持 `page.tsx` 纯净，尽量让它是 Server Component。看到 `useState` 就手抖一下，想想能不能把这个状态下沉到更小的子组件里。

---

## Part 3: 全局状态 Context 与 Zustand

当 URL 放不下（如复杂对象），且状态需要在多个互不相干的组件间共享时，我们才考虑全局状态。

### 3.1 选型指南
- **Context API**：React 原生，适合**低频更新**的全局配置（主题、多语言、用户信息）。
- **Zustand**：第三方库，适合**高频更新**或**复杂逻辑**（购物车、音乐播放器进度）。

### 3.2 Context 实战：主题切换
```tsx
// components/ThemeProvider.tsx
"use client"
import { createContext, useContext, useState, useEffect } from 'react'

// ...省略 Context 定义代码，详见脚本示例...

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  // 状态管理逻辑
  return <ThemeCtx.Provider value={{...}}>{children}</ThemeCtx.Provider>
}
```
使用时，只需在根布局 `layout.tsx` 或页面外层包裹 `ThemeProvider` 即可。

### 3.3 Zustand 实战：购物车
Zustand 的优势在于不仅代码简洁，而且可以避免不必要的重渲染。

```ts
// store/cart.ts
import { create } from 'zustand'

export const useCartStore = create((set) => ({
  items: [],
  count: 0,
  addItem: (product) => set((state) => ({ 
    items: [...state.items, product], 
    count: state.count + 1 
  })),
}))
```

组件内使用：
```tsx
const addItem = useCartStore((state) => state.addItem) // 只订阅 addItem
```

**避坑指南**：如果将 Zustand 状态持久化到 `localStorage`，在 Next.js 中要注意**水合不匹配（Hydration Mismatch）**问题。通常需要在 `useEffect` 中加载数据，或者使用专门的持久化中间件配置。

---

## Part 4: 表单状态管理

处理表单时，不要为每个 `input` 写一个 `useState`。如果表单有 20 项，你的代码会变得非常臃肿且性能低下（每次输入都重渲染）。

推荐组合：**React Hook Form + Zod**。

```tsx
// components/LoginForm.tsx
"use client"
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

const schema = z.object({
  email: z.string().email(),
  password: z.string().min(6)
})

export default function LoginForm() {
  const { register, handleSubmit, formState: { errors } } = useForm({
    resolver: zodResolver(schema)
  })

  return (
    <form onSubmit={handleSubmit((data) => console.log(data))}>
      <input {...register('email')} />
      {errors.email && <p>{errors.email.message}</p>}
      <button>登录</button>
    </form>
  )
}
```
**优势**：
1.  **非受控组件**：输入时不会触发全量重渲染，性能极佳。
2.  **代码简洁**：一行 `register` 搞定绑定。
3.  **类型安全**：Zod 保证了前后端校验逻辑的一致性。

---

## 总结

### 核心口诀
1.  **能不 Client 就不 Client**：保持 `page.tsx` 的服务端纯洁性，交互逻辑隔离到小组件。
2.  **URL 即状态**：筛选、分页、搜索，第一时间想到 `searchParams`。
3.  **工具选对**：简单交互用 `useState`，全局共享用 `Zustand`，复杂表单用 `React Hook Form`。

祝大家编码愉快，我们下节课见！