# Next.js 课程第二讲：React 组件开发核心知识

## 前言

Hello，大家好，欢迎回到我们的 Next.js 系列课程。在上一节课中，我们初步了解了 Next.js 并成功初始化了一个项目。今天，我们将回归 React 的基础，快速巩固一些核心知识，因为这是构建 Next.js 应用的基石。

> 友情提示：如果你已经是 React 的高手，可以跳过本课程直接到下一节。

我们本次课程的示例代码是在上一节课创建的一个项目基础上去做一个进一步的开发。大家可以先打开我们的 next.js 项目的首页文件 `app/Page.tsx`，我已经把当前这个 home 组件里面的内容值改成这样一个 `div` 标签，仅仅渲染字符串 `Hello,next.js`。接下来我会带着大家创建一些新的 react 组件，并在 `Home` 组件里面去引用，渲染出来，帮助大家去熟悉 react 的一些核心的概念。 并了解在 next.js 当中使用react开发有什么需要注意的地方。

好废话不多说，我们开始吧。

## 第一部分：React 核心概念快速回顾

### 1. JSX 语法与函数式组件

上节课当中推荐大家在项目根目录下面创建一个 `components` 文件夹，这个文件夹下面用来放置未来自己开发的组件。比如在这里我们先写创建一个 `HomePage` 组件来管理本节课中所有的示例组件

```jsx
// components/HomePage.tsx
import { useState } from "react";

function HomePage() {
  const [count, setCount] = useState(0)

  return (
    <div >
      <p>你点击了 {count} 次</p>
      <button className="bg-red-500 text-white p-2 rounded-md" onClick={() => setCount(count + 1)}>
        点我
      </button>
    </div>
  )
}

// app/page.tsx
import HomePage from "@/components/HomePage";

export default function Home() {
  return (
    <div>
      hello, next.js
      <HomePage />
    </div>
  );
}


```

现在我们的 `HomePage` 组件已经开发好了，这个组件就是一个很普通的 react 组件。有一点需要注意的是，在文件的顶部有一个 `use client` 这样一串字符串，我们把它可以叫做是指令，后面会给大家讲这个指令的高阶用法，这里只需要了解下其基本概念。

> 指令 `use client` 是告诉 next.js 这个组件是一个客户端组件，它需要在浏览器端运行。因为在 next.js 的 `App Router` 当中，默认所有的组件都是服务端组件，它们在服务器端运行，不能访问浏览器端的 API。所以如果我们的组件需要访问浏览器端的 API，比如操作 DOM、使用浏览器端的事件、或者调用浏览器端的 API，那么我们就需要在组件的顶部添加 `use client` 指令。

我们在 `Home` 组件里面去把 `HomePage` 组件引用进来。浏览器端可以看到此组件已经渲染出来了。

> 注意：因为我们的 `HomePage` 组件是一个客户端组件，所以它可以访问浏览器端的 API，比如操作 DOM、使用浏览器端的事件、或者调用浏览器端的 API。但是如果我们的组件是一个服务端组件，那么它就不能访问浏览器端的 API。

### 2. Props：让组件可复用

接下来我们会介绍在 react 组件当中 `props` 的一个核心的作用是什么？那我们写一个新的组件，比如就叫 `Greeting`，并在 `HomePage` 中引用组件 `Greeting` 组件

```tsx
// components/Greeting.tsx
// 注意：在 Next.js + TypeScript 中，我们需要为 props 定义类型
type GreetingProps = {
  name: string
}

export default function Greeting({ name }: GreetingProps) {
  return <p>你好, {name}！</p>
}
```

- **在 `app/page.tsx` 中使用**：

```tsx
import Greeting from '@/components/Greeting' // 假设已配置路径别名

export default function HomePage() {
  return (
    <div>
      <h1>欢迎！</h1>
      <Greeting name="世界" />
      <Greeting name="Next.js" />
    </div>
  )
}
```

因为我们使用 TypeScript 来开发组件，所以需要为组件 `props` 定义类型。我们定义了一个 `type`，它包含一个 `string` 类型的 `name` 字段。接着，我们在 Home 页面中引用 `Greeting` 组件。由于 `name` 是一个必需的 props字段，我们需要在调用`Greeting` 组件的时候给 name 字段赋值，比如 'Next.js'。大家可以看到，我们传递了不同的 `name` 值，比如 'React' 和 'Next.js'，组件也相应地展示了不同的内容。这个例子主要是为了帮助大家理解 `props` 在 React 中的作用。

> 在 react 组件当中，`props` 其实就是父组件向子组件传递数据的一种方式。正常情况下，`props` 它是只读的，不应该去修改它。尽管在 js 当中，你可以通过修改深层的嵌套对象的这种方式去改变父组件传递下的 `props`，但这样是违背的 react 的一个核心原则，使react组件树当中数据流变得混乱。

### 3. State (`useState`)：组件的内部状态

`state` 表示的就是 react 组件的一个内部状态。比如说我们通过一些 `button` 的`click` 事件触发了组件内部的某些数据的改变，然后 react 会自动的重新渲染组件，从而反映这种最新的状态。

> 注意：在 Next.js + TypeScript 中，我们同样需要为 `state` 定义类型，但基本类型数据`（如 number、string、boolean）`不需要额外定义，因为 React 会自动推断它们的类型。

> 总结一下：`props` 和 `state` 的主要的区别，`props` 它其实是从当前组件的外部传入的，一般就是从它的父组件传递下来的，而 `state` 是组件内部的一个状态的记录。

## 第二部分：Hooks 实战与核心开发模式

我们会带领大家亲手编写几个组件以及在组件内部使用`hooks`，比如说去使用 `useState` `useEffect` 这样一些最常见的 `hooks`。

### 1. `useState` 实战：构建一个计数器

让我们回到 `HomePage` 这个组件。可以看到 `HomePage` 组件目前是没有用 `props` 也没有去使用 `state`。接下来我们去添加 `useState` 这个 `hooks`。

```tsx
'use client' // 重要的提示：因为用到了 useState，这是一个客户端组件

import { useState } from 'react'

export default function HomePage() {
  const [count, setCount] = useState(0) // 初始状态为 0

  return (
    <div>
      <p>你点击了 {count} 次</p>
      <button className="bg-red-500 text-white p-2 rounded-md" onClick={() => setCount(count + 1)}>
        点我
      </button>
      <Greeting name="react" />
      <Greeting name="nextjs" />
    </div>
  )
}
```

在这个 `button` 的 `click` 事件，也就是单击这个 `button` 的时候，我们会给这个 `count` 这个 `state` 去加1，你一直点它会一直加1。

回到编辑器，大家会注意到组件文件顶部有一个 `use client` 指令。现在，我们试着把它注释掉，然后看看浏览器会发生什么。页面出现了构建错误`（build error）`，错误信息告诉我们，这个组件使用了 React Hook `useState`，而 Hooks 只能在客户端组件`（Client Component）`中使用。要修复这个错误，就必须在这个`文件或者它的父组件`中声明 `use client`。所以，一旦我们移除 `use client`，组件在 Next.js 中就会编译失败。我们把它恢复，编译就通过了。这就是 `use client` 的核心作用。

* 'use client' build error

  ```js
  installHook.js:1 ./components/HomePage.tsx:3:10
  Ecmascript file had an error
    1 | // 'use client' // 重要的提示：因为用到了 useState，这是一个客户端组件
    2 |
  > 3 | import { useState } from "react";
      |          ^^^^^^^^
    4 |
    5 | export default function HomePage() {
    6 |   const [count, setCount] = useState(0) // 初始状态为 0

  You're importing a component that needs `useState`. This React Hook only works in a Client Component. To fix, mark the file (or its parent) with the `"use client"` directive.

   Learn more: `https://nextjs.org/docs/app/api-reference/directives/use-client`

  Import trace:
    Server Component:
      ./components/HomePage.tsx
      ./app/page.tsx
  overrideMethod	@	installHook.js:1
  ```

> 大家只需要知道，只要是组件当中用到 `hooks`或使用只有在浏览器当中才存在的一些 api。比如说 `document` 对象，那么你的组件必须是支持 `use client` 指令。如果组件的父组件已经指定了`use client`，那么本组件可以省略掉这个的指令。

### 2. 条件渲染：动态显示内容

条件渲染。根据某些条件去动态的显示哪些内容怎么去实现，那我们编写一个新的组件 `ConditionalRenderPage`。

```tsx
// components/ConditionalRenderPage.tsx
import { useState } from 'react'

export default function ConditionalRenderPage() {
  const [isVisible, setIsVisible] = useState(true)

  return (
    <div>
      <button className='bg-blue-500 text-white p-2 rounded-md' onClick={() => setIsVisible(!isVisible)}>
        切换显示/隐藏
      </button>
      {/* 推荐：使用三元运算符，当条件为 false 时返回 null，确保不会意外渲染任何内容 */}
      {isVisible ? <p>这段文字现在是可见的。</p> : null}

      {/* 为了对比，这里展示 && 的用法。注意前面讲解中提到的潜在问题。 */}
      {/* isVisible && <p>这段文字现在是可见的。</p> */}
    </div>
  )
}

// components/HomePage.tsx
export default function HomePage() {
  const [count, setCount] = useState(0) // 初始状态为 0

  return (
    <div>
      <p>你点击了 {count} 次</p>
      <button className="bg-red-500 text-white p-2 rounded-md" onClick={() => setCount(count + 1)}>
        点我
      </button>
      <Greeting name="react" />
      <Greeting name="nextjs" />
      <ConditionalRenderPage />
    </div>
  )
}
```

在React中进行条件渲染时，三元运算符在条件为假时返回`null`，确保不渲染任何多余内容。而`&&`运算符在处理数字`0`这样的“假值”时，会直接将`0`渲染到页面上，可能导致非预期的显示问题。

### 3. 列表渲染 (`.map`) 与 `key` 属性 

接下来我们学习列表渲染，如此处的 `ProductList` 组件所示，我们通过 `map()` 方法遍历数组来动态渲染列表项。在渲染列表时，必须为每个列表项指定一个唯一的 `key` 属性，这对于 React 高效更新至关重要。虽然可以使用数组索引作为 `key`，但当列表动态变化（如增删或排序）时，这会引发性能问题和 bug，因此强烈建议使用数据中稳定且唯一的 ID。

```tsx
// 这是一个服务端组件，因为数据是静态的
const products = [
  { id: 1, name: '笔记本电脑' },
  { id: 2, name: '智能手机' },
  { id: 3, name: '无线耳机' },
]

export default function ProductListPage() {
  return (
    <div>
      <h2>商品列表</h2>
      <ul>
        {products.map((product) => (
          <li key={product.id}>
            {product.name}
          </li>
        ))}
      </ul>
    </div>
  )
}
```

## 第三部分：组件生命周期与组合

接下来我们会带着大家了解组件的一些生命周期和组件组合的实现。

### 1. `useEffect`：处理副作用

`useEffect` 用于在函数组件中执行副作用操作，比如数据获取、订阅或手动更改 DOM。它在组件渲染到屏幕后执行。`useEffect` 的第二个参数是一个可选的依赖数组，用于控制副作用的执行时机。如果依赖数组中的某个值发生变化，副作用函数就会重新执行。

```tsx
import { useState, useEffect } from 'react'

export default function EffectDemoPage() {
  const [count, setCount] = useState(0)

  // 注意：这个组件是客户端组件，因为它使用了 useEffect 钩子和浏览器 api 也就是document.title
  // 客户端组件可以访问浏览器 API，如 document.title，服务端组件不能访问浏览器 API，因为它们在服务器上运行
  // 每次 count 变化时，更新浏览器标题
  useEffect(() => {
    document.title = `你点击了 ${count} 次`
  }, [count]) // 依赖数组，只有 count 变化时才执行

  return (
    <div>
      <p className="text-lg font-bold mb-4">查看浏览器标签页标题的变化</p>
      <button className="bg-blue-500 text-white p-2 rounded-md" onClick={() => setCount(count + 1)}>
        增加计数
      </button>
    </div>
  )
}
```

在这个新组件 `EffectDemoPage` 中，我们引入了 `useEffect` 这个 Hook 来处理渲染之外的“副作用”，比如操作浏览器 API。`useEffect` 接收一个副作用函数和一个依赖数组，每当依赖数组中的 `count` 状态因点击按钮而改变时，它都会重新执行我们的副作用函数来更新浏览器标签页的标题。因此，你可以把 `useEffect` 理解为传统类组件中 `componentDidMount` 和 `componentDidUpdate` 这两个生命周期方法的集合体，用于在组件加载完成和状态更新后执行操作。

### 2. 组件组合与 `children` props

React 的一个强大之处在于组件组合。我们可以创建通用容器组件，通过 `children` prop 渲染任意内容。

```tsx
// components/Card.tsx
import React from 'react'

type CardProps = {
  children: React.ReactNode // ReactNode 类型允许任何可渲染的内容
}

export default function Card({ children }: CardProps) {
  return (
    <div style={{ border: '1px solid #ccc', padding: '16px', borderRadius: '8px' }}>
      <div className="font-bold text-lg mb-2">
        卡片主标题
      </div>
      {children}
    </div>
  )
}
```

- **使用**：

```tsx
import Card from '@/components/Card'

export default function CompositionPage() {
  return (
    <Card>
      <h2>这是一个卡片子标题</h2>
      <p>这是卡片的内容，可以放任何东西。</p>
    </Card>
  )
}
```

在这个例子中，我们创建了一个通用的 `Card` 组件，它通过一个特殊的 `children` prop 来接收和渲染任何传递给它的内容。如 `CompositionPage` 组件所示，我们可以在 `<Card>` 标签内部直接嵌套其他元素（如标题和段落），这些嵌套的内容会自动作为 `children` prop 传递进去。这种“组合”模式让 `Card` 成为一个灵活的容器，极大地提高了组件的复用性，其功能类似于 Vue 中的插槽（slots），但实现上更为直接和灵活。

## 总结

好的，今天的代码演示就到这里。我们来快速回顾一下本节课的主要内容：

- 首先，我们复习了 **React 的核心知识**，包括函数式组件、`props` 和 `useState`。
- 接着，我们探讨了 **条件渲染**，重点比较了三元运算符和 `&&` 运算符。
- 然后，我们学习了 **列表渲染** 和 **副作用处理**，强调了 `key` 的重要性以及 `useEffect` 的用法。
- 最后，我们通过 `children` prop 演示了强大的 **组件组合** 功能。

这些都是后续 Next.js 开发中会频繁用到的基础知识，希望大家能熟练掌握。

今天的课程就到这里，我们下节课再见！