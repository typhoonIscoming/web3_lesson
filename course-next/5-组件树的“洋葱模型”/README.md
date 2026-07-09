## 前言

哈喽，大家好，欢迎来到 Next.js 系列课程的第五课！在前面的课程里，我们已经熟悉了 App Router 的基本路由和文件约定。今天，我们要更进一步，深入它的‘灵魂’——布局与页面系统。我们会详细拆解 `layout.tsx`、`page.tsx` 还有那个有点特别的 `template.tsx`，看看它们是怎么像套娃一样层层嵌套，构建出复杂又高效的 UI 的。好了，废话不多说，我们马上开始！

### 1. 核心理念：组件树的“洋葱模型”

‘布局共享、页面独立’。当我们访问一个路由时，Next.js 会把根布局、子布局一层层包起来，最后呈现页面。你可以把它想成套娃或洋葱，每一层都是一个稳定的外壳，最里面才是页面的具体内容。`app/` 下的每个子文件夹，对应 URL 的一段，也对应界面的一层。

- `app/` 目录下核心文件分工：
  - **布局** `layout.tsx`：在多个页面之间共享的外壳（导航栏、页脚）；切页面时不重新渲染，里面的状态会保留。
  - **页面** `page.tsx`：某个 URL 下的独立内容，是路由最里面的那层，真正的页面。

- **渲染关系**：
  访问页面时，从根布局到子布局一层层包起来，再渲染页面。`RootLayout -> (SegmentLayout) -> ... -> Page`

“洋葱模型先放在脑子里，接下来我们看它的起点——根布局。”

### 2. 根布局(`app/layout.tsx`)：一切的起点

根布局就是全站的外壳。它必须返回 `<html>` 和 `<body>`，这不是随便写，是浏览器需要的完整文档结构。像全局导航、字体设置、Provider 都放在这里。页面切换的时候，这些不动，体验更稳。

```tsx
// app/layout.tsx
import './globals.css'; // 引入全局样式

// 定义 Metadata，用于 SEO
export const metadata = {
  title: '我的 Next.js 应用',
  description: '由 Next.js 驱动',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="zh-CN">
      <body>
        <header>我是全局导航栏</header>
        {children}
        <footer>我是全局页脚</footer>
      </body>
    </html>
  );
}
```

> 记住：根布局不随页面切换而重建，外壳稳定，体验更稳。

### 3. 嵌套布局与页面(`layout.tsx` & `page.tsx`)

现在我们访问 `/dashboard` 或者 `/dashboard/settings`，左边的侧边栏一直都在，不会因为页面切换而消失。这就是嵌套布局的威力。`DashboardLayout` 成为了所有 `/dashboard` 下级页面的共享外壳。记住：布局做外壳，页面做内容。

> 任何目录下都能建 `layout.tsx`，作为该路径及子路径的共享外壳；有 `page.tsx` 才能访问这个分段。

```tsx
// app/dashboard/layout.tsx
import Link from 'next/link';

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <section className="flex">
      <nav className="w-1/4 bg-gray-200 p-4">
        <h2>后台管理</h2>
        <ul>
          <li><Link href="/dashboard">仪表盘</Link></li>
          <li><Link href="/dashboard/settings">设置</Link></li>
        </ul>
      </nav>
      <main className="w-3/4 p-8">{children}</main>
    </section>
  );
}
```

```tsx
// app/dashboard/page.tsx
import Link from 'next/link';

export default function Page() {
  return (
    <section>
      <h1>仪表盘</h1>
      <p>欢迎回来！这里是你的数据总览。</p>
      <p>
        前往 <Link href="/dashboard/settings">设置</Link>
      </p>
    </section>
  );
}
```

```tsx
// app/dashboard/settings/page.tsx
export default function SettingsPage() {
  return (
    <section>
      <h1>设置</h1>
      <p>在这里可以调整你的偏好与账户信息。</p>
    </section>
  );
}
```

 

> 演示建议：在 `/dashboard` 和 `/dashboard/settings` 来回切，左侧导航始终存在，说明布局状态与结构被保留。

### 4. 特殊的 `template.tsx`：需要“重新开始”的场景

进入 `template.tsx` 就像重新开一局：每次进入都会重置状态与副作用，入场动画也能次次播放。和 `layout.tsx` 不同，`layout` 会保留状态，适合做持久交互。

```tsx
// app/posts/[slug]/template.tsx
'use client';
import { useEffect, useState } from 'react';

export default function Template({ children }: { children: React.ReactNode }) {
  const [isMounted, setIsMounted] = useState(false);

  useEffect(() => {
    setIsMounted(true);
  }, []);

  return (
    <div
      style={{
        opacity: isMounted ? 1 : 0,
        transition: 'opacity 0.5s ease-in-out',
      }}
    >
      {children}
    </div>
  );
}
```

```tsx
// app/posts/layout.tsx
'use client';
import { useState } from 'react';

export default function PostsLayout({ children }: { children: React.ReactNode }) {
  const [likes, setLikes] = useState(0);
  return (
    <div style={{ display: 'flex', gap: 24 }}>
      <aside>
        <button onClick={() => setLikes((n) => n + 1)}>点赞 {likes}</button>
        <p>切换文章时，这里的计数会保留（布局状态）。</p>
      </aside>
      <main>{children}</main>
    </div>
  );
}
```

```tsx
// app/posts/[slug]/page.tsx
import Link from 'next/link';

export default function Page({ params }: { params: { slug: string } }) {
  return (
    <article>
      <h1>文章：{params.slug}</h1>
      <p>这里是 {params.slug} 的正文内容……</p>
      <hr />
      <p>
        切换文章：
        <Link href="/posts/next">下一篇</Link>
        {' '}
        ·
        {' '}
        <Link href="/posts/prev">上一篇</Link>
      </p>
    </article>
  );
}
```

> 演示建议：快速在两篇文章间切换，观察淡入动画每次都重新播放；而布局里的“点赞”计数不变，体现两者差异。

### 5. 路由分组与共享布局

括号目录不会进 URL，但能让多个页面共享同一个‘大外壳’。很适合营销页这类一套皮包多个页面。示例里我们把分组放在 `app/mkt/` 下，路径更清晰。

```tsx
// app/mkt/(marketing)/layout.tsx
import Link from 'next/link';

export default function MarketingLayout({ children }: { children: React.ReactNode }) {
  return (
    <section>
      <nav>
        <Link href="/mkt">首页</Link>
        <Link href="/mkt/pricing">定价</Link>
      </nav>
      {children}
    </section>
  );
}
```

```tsx
// app/mkt/(marketing)/page.tsx
export default function Page() {
  return (
    <section>
      <h1>首页</h1>
      <p>这是营销落地页的首页。</p>
    </section>
  );
}
```

```tsx
// app/mkt/(marketing)/pricing/page.tsx
export default function PricingPage() {
  return (
    <section>
      <h1>定价</h1>
      <ul>
        <li>基础版：免费</li>
        <li>专业版：￥99/月</li>
      </ul>
    </section>
  );
}
```

 

> 演示建议：在 `/mkt` 和 `/mkt/pricing` 来回切，导航栏始终来自同一个分组布局；注意 URL 不包含 `(marketing)`，分组只影响文件组织与共享外壳。

### 6. 布局中的状态与交互

布局默认是服务端组件；需要在布局里放交互状态（比如搜索框），就用 `'use client'` 把它转为客户端组件。布局状态在页面切换时会保留，体验更好。

```tsx
// app/products/layout.tsx
'use client';
import { useState } from 'react';

export default function ProductsLayout({ children }: { children: React.ReactNode }) {
  const [query, setQuery] = useState('');
  return (
    <div>
      <aside>
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="搜索产品..."
        />
      </aside>
      <main>{children}</main>
    </div>
  );
}
```

```tsx
// app/products/page.tsx
import Link from 'next/link';

export default function Page() {
  return (
    <section>
      <h1>产品列表</h1>
      <ul>
        <li><Link href="/products/1">产品 1</Link></li>
        <li><Link href="/products/2">产品 2</Link></li>
        <li><Link href="/products/3">产品 3</Link></li>
      </ul>
    </section>
  );
}
```

```tsx
// app/products/[id]/page.tsx
export default function ProductDetail({ params }: { params: { id: string } }) {
  return (
    <article>
      <h1>产品详情 {params.id}</h1>
      <p>这里是产品 {params.id} 的详情。</p>
    </article>
  );
}
```

> 演示建议：在搜索框输入内容，进入某个产品详情再返回列表，搜索内容仍保留；切换不同详情页，搜索状态不变。

 

## 总结与作业

- 总结：今天我们深入学习了 App Router 的布局系统，搞懂了 `layout`, `page`, `template` 的“铁三角”关系。

> 这节课就到这儿，我们下节课再见！