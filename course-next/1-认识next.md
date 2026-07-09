# Next.js 基本认知和项目初始化

Hello 大家好！今天这节课是我们整个 next.js 系列课程的第一部分。在这一课当中，我会带着大家完成对 next.js 的一个基本的认知，以及快速上手 next.js 的一个项目开发。

这节课主要包括以下三部分内容：

1.  **第一部分：** 了解 Next.js 是什么、为何使用、优缺点、使用场景以及一些核心概念（如 SSR/SSG、App Router）。
2.  **第二部分：** 从零到一初始化一个 Next.js 项目，并体验开发一个 React 组件。
3.  **第三部分：** 了解 Next.js 与 TypeScript 的深度集成，以及全局配置文件中的核心字段及其作用。

## Next.js 是什么

### 1. Next.js 它是什么

官方定义中，Next.js是一个基于 react 的用来开发 web 应用的一个全栈框架。也就是说，我们不仅可以做前端页面的开发，也能够做后端API 服务层的开发，去操作数据库，去访问第三方API服务等。

Next.js原生内置了对文件路由（App Router&Pages Router）、API 路由、嵌套布局（layout）、SSR/SSG/ISR、缓存、错误处理、图片优化、本地开发调试、部署（vercel） 的完美支持，从而能够帮助我们实现一个开箱即用0成本配置的全栈开发。

### 2. Next.js 的核心价值主要体现在以下几个方面：

- **开箱即用**：内置路由、SSR/SSG 渲染机制、数据获取模型和 React Server Components (RSC, React 服务器组件)。
- **性能与SEO**：提供优秀的性能和 SEO 支持，平衡了性能与开发效率。
- **全栈开发**：支持前端组件开发和后端 API 服务编写。
- **开发者体验**：提供快速热更新（Fast Refresh）和通过 Vercel 实现的一键式部署（Zero-config Deployment）。

### 3. Next.js 适合用在哪些地方？

- **面向公众的网站**：像电商网站、内容丰富的博客或新闻网站、以及大型门户网站。
- **企业内部系统**：例如公司内部的管理后台、数据看板等。
- **需要快速上线的项目**：当你需要快速开发和交付一个产品原型或中小型项目时，Next.js 也是一个很好的选择。

### 4. Next.js 三种主要渲染机制

- **SSR（Server-Side Rendering, 服务器端渲染）**，在每次请求页面的时候，在服务器端去生成 HTML，适合动态、个性化页面。
- **SSG（Static Site Generation, 静态站点生成）** 它在系统本地构建时生成静态 HTML，适合内容稳定、SEO 友好页面。
- **ISR（Incremental Static Regeneration, 增量静态再生成）**：在静态与动态之间做平衡，按失效策略后台再生成。

### 5. Next.js 的 Router 模式以及两种 Router 的差异

1. **App Router（应用路由）**是官方推荐的路由模式（Next.js 13 引入，13.4 稳定），其核心特点包括：

- 根目录位于 `app` 文件夹
- 默认采用 React Server Components（RSC, React 服务器组件），开箱即用
- 原生支持嵌套布局，可轻松实现共享 UI 与数据流
- 提供丰富的文件路由系统，支持动态路由、参数捕获、捕获所有路由等。

2. **Pages Router（页面路由）** 是Next.js 的经典方案（自 Next.js 1.0 起支持）

- 目录结构基于 `pages` 文件夹
- 默认采用 React 客户端组件（Client Components）
- 嵌套布局（layout）需要手动实现，不如 App Router 方便
- 功能虽丰富，但在灵活性与未来特性支持上已不及 App Router
- 新项目建议优先选用 App Router

到此的话，我们那这一节课的第一部分内容就先介绍到此介绍到这里。

## 初始化 Next.js 项目

### 准备工作

接下来我会带领大家从零到一去初始化一个 next.js 项目， 首先我们需要去准备好本地开发环境，确保你的系统满足以下要求：

- Node.js 20.9+
- macOS, Windows (支持WSL), or Linux

### 初始化项目

接下来打开终端命令行工具，在这里我主要是用的 mac 的命令行工具，创建新的 Next.js 应用程序最快的方法是使用 `create-next-app` ，它会为你自动设置所有内容。要创建项目，运行以下命令行：

```bash
npx create-next-app@latest
```

安装时，你会看到以下提示：

```text
What is your project named? nextjs-app
Would you like to use the recommended Next.js defaults?
    Yes, use recommended defaults - TypeScript, ESLint, Tailwind CSS, App Router, Turbopack
    No, reuse previous settings
    No, customize settings - Choose your own preferences
```

在这里我们选择第一个选项，使用推荐的 Next.js 默认配置。

> Turbopack 现在是默认的打包器。要使用 Webpack，请运行 `next dev --webpack` 或 `next build --webpack` 。有关配置详情，请参阅 [Turbopack 文档](https://nextjs.org/docs/app/building-your-application/configuring/turbopack)。

在提示完成后， create-next-app 会创建一个以你的项目名称命名的文件夹并安装所需的依赖项，大家有兴趣可以去看一下[官方文档](https://nextjs.org/docs/app/api-reference/cli/create-next-app)。

好！现在我们的第一个 Nextjs项目已经初始化成功了， 接下来我们简单了解下核心目录结构。

### 目录结构

- `package.json`：项目配置文件，包含依赖项、脚本命令和项目元数据。其中 scripts 部分定义了常用命令：`dev、build、start、lint`。
    - `dev`：以开发模式启动 Next.js，支持热模块重载、错误报告等功能。
    - `build`：创建经过优化的生产构建，并且显示每个路由的信息。
    - `start`：在生产模式下启动 Next.js，注意我们的应用应该先使用 `next build` 进行编译。
    - `lint`：运行 `ESLint` 检查项目代码，确保符合 Next.js 的编码规范。

这里我们直接执行 `dev` 命令，启动我们的项目。

```bash
npm run dev
```

然后我们可以使用提示中的 `localhost:3000`  在本机浏览器打开默认首页。并且在react devtools 的 components tab 可以看到当前页面的react 组件树情况。

- `app` 目录：这是 Next.js 应用的核心目录，包含了所有的路由和页面组件。
    -  **`favicon.ico`**: 浏览器标签页的图标。
    -  **`global.css`**: 全局 CSS 样式文件，在本项目中结合 Tailwind CSS 使用，用于配置全局样式。
    -  **`layout.tsx`**: Next.js 应用的根布局组件。这是一个 React 组件，用于包裹所有页面，管理字体、元数据等。**需要注意的是，除了根布局外，Next.js 中的每个页面或路由段都可以定义自己的布局组件，实现更灵活的页面结构管理。**
    -  **`page.tsx`**: 应用的主页面，作为默认首页。它位于 `app` 目录下，并在 `layout.tsx` 组件中渲染。

- `public` 目录: 这个文件夹主要用于存放项目中的静态资源，比如我们常用的 SVG、PNG 等图片，或者一些字体文件，都可以放在 `public` 目录下。
- `.eslintrc.js`: 它是 ESLint 的配置文件。它是默认生成的，我们暂时无需修改，只需了解其用途即可。
- `next-env.d.ts`: 这是一个Next.js 项目类型声明文件，通常我们不需要去修改它。
- `next.config.ts`: 这是 Next.js 的全局配置文件。由于Next.js 提供了许多开箱即用的功能，已经内置了大量默认配置，所以我们暂时不需要修改。后续如果有更高阶的需求，可以参考官方文档去进行配置，比如自定义路由、环境变量、服务器端渲染等，这里就不展开介绍了。
- `postcss.config.js`: 这是 PostCSS 的全局配置文件。目前里面是一些默认配置，预留给我们进行自定义。
- `tsconfig.json`: 这是 TypeScript 的编译配置文件。后续我们会讲解其中一些核心的配置项以及它们的作用。

### 组件开发示例

当前项目首页就是 `page.tsx` 文件中的 `Home` 组件。我们可以编写一个 React 组件，并在 `Home` 组件中使用它，来帮助大家简单了解 Next.js 的组件开发流程。

修改 `page.tsx` 文件内容后，Next.js 会自动编译和更新页面。需要注意的是，在 Next.js 中，`page.tsx` 文件默认导出的都是服务端组件（Server Component）。后面我们会详细讲解服务端组件和客户端组件的区别。目前大家只需要了解，它在写法上和普通的 React 组件没有本质区别。

接下来给大家演示一下如何在 nextjs 项目中开发一个简单的组件 `Heading`，并在页面中渲染出来。

* 组件开发示例

首先建议在根目录下创建一个 `components` 目录，然后在这个目录下新建自己的 React 组件，这里创建一个 `Heading.tsx` 文件，用于渲染一个简单的标题组件。

```jsx
// components/Heading.tsx
import React from 'react';

const Heading = () => {
  return <h1>hello nextjs</h1>;
};
```

```jsx
// app/page.tsx
import Heading from "@/components/Heading";

const Home = () => {
  return (
    <>
      <Heading />
    </>
  );
};

```

* tsconfig.json 配置

我们还需要添加一个新的 `paths` 配置项，用于配置路径别名。这里我们配置 `@/components/*` 指向 `components/*`，这样在组件中引入其他组件时，就可以使用 `@/components/组件名` 来引入，而不需要使用相对路径。

```json
    "paths": {
      "@/components/*": ["components/*"],
    },
```

第二部分中我们已经带领大家从零到一创建了一个 next.js 项目，并且写了一个简单的 React 组件，而且在 nextjs 项目中也能够正常的渲染。

## 了解 Next.js 与 TypeScript 的深度集成

接下来的第三部分内容中我们会来了解 Next.js 与 TypeScript 的深度集成。由于 Next.js 对 TypeScript 的开箱即用支持，我们在开发 Next.js 项目组件时，通常直接使用 tsx 文件格式即可，无需额外配置。

```
 - layout.tsx
 - page.tsx
```

使用官方脚手架创建项目时会自动生成 `tsconfig.json` 文件，其中包含了一些预设的配置项。Next.js 在构建过程中会依据这些配置进行类型检查，并为主流 IDE 提供智能代码提示功能。

* `tsconfig.json` 关键配置项：

- `strict: true`：开启最严格类型检查，减少运行时错误。
- `baseUrl` / `paths`：别名与模块解析，改善大型项目可维护性。
- `moduleResolution: "bundler"`（TS5 推荐）或 `"node"`：配合现代打包器解析 ESM/导入，Next 项目更倾向 `"bundler"`。
- `jsx: "preserve"` 或 `"react-jsx"`：App Router + React 18 场景下，脚手架会给出合适默认。
  - "react-jsx"	使用新版 JSX 转换，不需显式导入 React，	React 17+ 推荐
- `types`: 指定类型包（如 `["node"]`），控制全局类型注入，避免污染。
- `target` 与 `lib`：编译目标与运行时能力（如 `ES2020`、`DOM`）。
- `resolveJsonModule: true`：允许导入 JSON，常用于配置。
- `skipLibCheck: true`：跳过依赖库检查，加快构建（权衡：可能隐藏库内类型问题）。
- `noEmit: true`：仅类型检查不输出 JS，交由 Next 构建处理。
- `incremental: true`：加快本地类型检查。

## 总结

好了，今天课程的三个部分就都讲完啦，我们来快速总结一下今天都学了些什么：

- **认识 Next.js**：我们了解了 Next.js 的基本概念、核心优势以及它适合用在什么样的业务场景里。
- **项目初始化**：我们一起从零开始，用 Next.js 官方脚手架创建了一个新项目，并熟悉了它的默认目录结构和工程规范。
- **TypeScript 集成**：我们深入了解了 Next.js 是如何与 TypeScript 深度集成的，包括它默认的 TS 配置项以及各个字段的含义。

好，那今天这节课程就到此结束了。