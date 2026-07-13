# 深入理解 Next.js国际化多语言（i18n）方案与实践

本文面向 Next.js 初学者。内容按“先跑通 → 再理顺 → 最后可扩展”的顺序，带你搭建一个中英双语站点，并补齐语言切换、SEO 与性能拆分的常见做法。

**适用版本**：Next.js 16.x（App Router）  
**核心库**：`next-intl`  
**适合人群**：刚开始用 App Router，希望做双语/多语言站点  
**目标产出**：

1. 一个可运行的 `/zh` 与 `/en` 双语站点（URL 带语言前缀）
2. 翻译文件的组织方式（`messages/`）
3. 语言切换器：切换后保持当前页面路径不变
4. SEO 最小实现：`hreflang` + 多语言 `sitemap`
5. 【了解即可】性能思路：按命名空间注入 messages，避免把全部翻译塞进浏览器

**核心理念**：

1. **语言落在 URL 上更可靠**：`/zh/about` 与 `/en/about` 可分享、可收藏、可被搜索引擎理解。
2. **翻译 key 要稳定**：文案可以随时改，但 key 别轻易改名，避免全项目连锁修改。
3. **服务端负责首屏文本**：首屏更快、更利于 SEO；客户端主要负责交互区域的翻译。
4. **路由配置只写一份**：`routing.ts` 是“单一真相来源”，middleware 与导航复用它。
5. **messages 按需注入**：翻译文件变大后，避免无用文案进入浏览器。

**学习方式建议**：

- 第一遍：照着做，先把 `/zh` 和 `/en` 跑通。
- 第二遍：再做“结构升级”，把 messages 拆命名空间、加 `hreflang` 与 `sitemap`、尝试按需注入。
- 每做完一步，都按文中的“如何验证”检查一遍，出错更容易定位。

---

## 一、核心理念：i18n 到底在解决什么

做国际化（i18n），你可以先把问题拆成三块：

1. **路由**：用户如何进入不同语言版本（例如 `/zh/about`、`/en/about`）
2. **文案**：同一段文字如何维护不同语言（例如 `HomePage.title` 的中文/英文）
3. **切换**：用户切换语言时，最好仍停留在同一页面（从 `/zh/about` → `/en/about`）

你可以把它理解成：我们把“语言”变成一个明确的维度。页面结构仍然是同一套，但同一个 key（例如 `HomePage.title`）会因为语言不同而返回不同的文字。

对初学者来说，最容易混淆的是“路由”和“翻译”。这两者是强相关但不同层的问题：

- **路由**决定你现在处在什么语言环境（`/zh` 还是 `/en`）
- **翻译**决定你在这个语言环境里拿到什么文案（`t('title')` 具体是中文还是英文）

这节课的策略是：先把路由与基础配置搭好（让 `/zh` 和 `/en` 都能访问），再开始“怎么翻译”（服务端与客户端各一套），最后补齐 SEO 与性能优化点（`hreflang`、`sitemap`、按命名空间注入）。

本文刻意只覆盖“从 0 到 1”最关键的主线：不会讨论翻译平台接入、自动翻译、后台可视化管理、多域名 SEO 等扩展话题，但结构上已经为后续扩展留好了位置。

---

## 二、安装与基础配置（让项目先跑起来）

### 2.1 安装依赖

如果你已经有一个 Next.js 16 App Router 项目，可以直接进入安装步骤。否则建议从零创建一个干净的模板项目，这样不容易被旧配置干扰：

```bash
npx create-next-app@latest next-intl-demo --ts --app --eslint
cd next-intl-demo
```

安装 `next-intl`：

```bash
npm install next-intl
```

### 2.2 准备翻译文件（messages）

在项目根目录创建 `messages/`，用 JSON 管理不同语言的文案。

这里建议你按“命名空间（顶层对象）→ 具体 key（字段）”来组织，原因是：

- 初学者更容易定位：我是在“首页文案”还是“导航文案”
- 后续更容易按需注入：只把某些命名空间发给客户端

另外，key 的命名建议“描述含义，而不是描述展示方式”。例如用 `title/subtitle`，而不是 `bigText/smallText`。因为 UI 可能改版，但文案含义通常不变。

**文件路径**：`messages/zh.json`

```json
{
  "HomePage": {
    "title": "欢迎来到我的博客",
    "subtitle": "分享技术，记录生活"
  },
  "Navigation": {
    "home": "首页",
    "about": "关于"
  },
  "LanguageSwitcher": {
    "label": "语言",
    "zh": "中文",
    "en": "English"
  }
}
```

**文件路径**：`messages/en.json`

```json
{
  "HomePage": {
    "title": "Welcome to my Blog",
    "subtitle": "Sharing tech, recording life"
  },
  "Navigation": {
    "home": "Home",
    "about": "About"
  },
  "LanguageSwitcher": {
    "label": "Language",
    "zh": "中文",
    "en": "English"
  }
}
```

### 2.3 配置 next-intl 插件（Next.js 配置文件）

Next.js 需要通过插件知道如何加载 `next-intl` 的配置。

你可以先把它理解成：`next-intl` 会把“根据当前请求的语言加载 messages”的能力接到 Next.js 运行时里，这样在服务端组件里调用 `getTranslations()` / `getMessages()` 时，才知道去哪里读翻译文件。

本课采用 `i18n/request.ts` 作为请求配置入口文件（后面会创建它）。`next-intl` 插件会读取并使用这个入口。

**文件路径**：`next.config.mjs`（或 `next.config.js`）

```js
import createNextIntlPlugin from 'next-intl/plugin';

const withNextIntl = createNextIntlPlugin();

const nextConfig = {};

export default withNextIntl(nextConfig);
```

如果你的项目使用 CommonJS（`next.config.js`），写法类似：

```js
const createNextIntlPlugin = require('next-intl/plugin');

const withNextIntl = createNextIntlPlugin();

module.exports = withNextIntl({});
```

### 2.4 可选：Next.js 的 `i18n` 配置（了解即可）

`next.config` 的 `i18n.locales/defaultLocale/domainLocales` 更偏向多域名或旧路由体系的场景。我们本课使用 App Router + `next-intl` middleware 做语言前缀路由，所以先不用它也可以完整跑通。

小提醒：修改 `next.config.*` 后通常需要重启开发服务器，否则你可能会觉得“我改了但没生效”。

---

## 三、路由设计：让 URL 带上语言前缀

目标效果：所有页面都带语言前缀，例如：

- `/zh`
- `/en`
- `/zh/about`
- `/en/about`

### 3.1 推荐目录结构（最小可运行）

在 App Router 里，`app/[locale]/` 的含义是：`[locale]` 是一个动态路由片段，它会匹配 URL 的第一段。

- 访问 `/zh` 时，`locale` 的值就是 `zh`
- 访问 `/en/about` 时，`locale` 的值就是 `en`

这样做的好处是：语言选择天然就跟着 URL 走。你把链接发给别人，对方打开就直接是对应语言版本，不依赖浏览器的缓存、cookie 或本地存储。

```text
app/
  [locale]/
    layout.tsx
    page.tsx
    about/
      page.tsx
i18n/
  routing.ts
  navigation.ts
  request.ts
messages/
  en.json
  zh.json
middleware.ts
next.config.mjs
```

### 3.2 统一路由配置：`i18n/routing.ts`

这个文件是“语言路由的单一真相来源”，后续 middleware 与 navigation 会共享它。

这里有三个你需要理解的配置项：

1. `locales`：你支持哪些语言。想新增语言（比如日语），第一步通常就是把 `ja` 加进来。
2. `defaultLocale`：默认语言。结合 middleware 的跳转逻辑，访问 `/` 时会被送到默认语言（例如 `/zh`）。
3. `localePrefix`：URL 是否总是带语言前缀。本文用 `'always'`，规则更统一；等你更熟悉后，也可以改成 `'as-needed'`，让默认语言不带前缀（例如中文用 `/about`，英文用 `/en/about`），但那时你需要额外处理更多“有没有前缀”的分支。

**文件路径**：`i18n/routing.ts`

```ts
import {defineRouting} from 'next-intl/routing';

export const routing = defineRouting({
  locales: ['zh', 'en'],
  defaultLocale: 'zh',
  localePrefix: 'always'
});
```

### 3.3 请求侧配置：`i18n/request.ts`

这一步告诉 `next-intl`：针对某个 `locale`，应该加载哪份 messages。

你可以把 `request.ts` 理解成一个“翻译加载器”：

- 用户访问 `/zh`，这里就加载 `messages/zh.json`
- 用户访问 `/en`，这里就加载 `messages/en.json`

如果用户访问了你不支持的语言（例如 `/jp`），我们用 `notFound()` 直接返回 404。对于初学者来说，这比“悄悄兜底到默认语言”更容易发现问题，也更利于排查线上错误链接。

**文件路径**：`i18n/request.ts`

```ts
import {getRequestConfig} from 'next-intl/server';
import {notFound} from 'next/navigation';
import {routing} from './routing';

export const locales = routing.locales;

export default getRequestConfig(async ({locale}) => {
  if (!routing.locales.includes(locale as any)) notFound();

  return {
    messages: (await import(`../messages/${locale}.json`)).default
  };
});
```

### 3.4 中间件：访问 `/` 自动跳转到默认语言

**文件路径**：`middleware.ts`（项目根目录）

```ts
import createMiddleware from 'next-intl/middleware';
import {routing} from './i18n/routing';

export default createMiddleware(routing);

export const config = {
  matcher: ['/((?!api|_next|.*\\..*).*)']
};
```

`matcher` 的意思是：哪些路径需要经过这个中间件。这里我们排除了：

- `api/*`：API 路由通常不需要语言前缀
- `_next/*`：Next.js 内部资源
- `*.xxx`：静态文件（如图片、favicon、robots.txt 等）

此时访问 `http://localhost:3000` 会自动跳转到 `http://localhost:3000/zh`。

**如何验证（建议你做一遍）**：

1. 启动开发服务器：`npm run dev`
2. 打开 `http://localhost:3000`，确认跳转到 `/zh`
3. 访问 `http://localhost:3000/en`，确认能看到英文版本
4. 访问 `http://localhost:3000/jp`（不支持的语言），确认返回 404

---

## 四、在 Layout 注入 Provider（让客户端组件也能翻译）

服务端组件翻译可以直接在服务端执行，但客户端组件需要通过 Provider 拿到 messages。

你可以把 `NextIntlClientProvider` 理解成“翻译上下文的提供者”。只要某个客户端组件在它的包裹范围内，就可以使用 `useTranslations()` 读取翻译；反过来，如果组件不在这个 Provider 下，就会报错（这是初学者最常见的问题之一）。

同时别忽略 `<html lang={locale}>`：它会影响读屏软件（无障碍）、浏览器拼写检查，以及搜索引擎对页面语言的判断。做 i18n 时，这是一个非常基础但非常重要的细节。

**文件路径**：`app/[locale]/layout.tsx`

```tsx
import {NextIntlClientProvider} from 'next-intl';
import {getMessages} from 'next-intl/server';
import type {ReactNode} from 'react';

export default async function LocaleLayout({
  children,
  params
}: {
  children: ReactNode;
  params: {locale: string};
}) {
  const {locale} = params;
  const messages = await getMessages();

  return (
    <html lang={locale}>
      <body>
        <NextIntlClientProvider messages={messages}>
          {children}
        </NextIntlClientProvider>
      </body>
    </html>
  );
}
```

如果你希望构建时为每个语言生成静态参数（更接近“每个语言都有固定路由”的直觉），可以在同一个文件里额外导出：

```ts
import {routing} from '../../i18n/routing';

export function generateStaticParams() {
  return routing.locales.map((locale) => ({locale}));
}
```

---

## 五、翻译的两种姿势：服务端与客户端

### 5.1 服务端页面翻译（RSC：更利于 SEO）

服务端翻译的直觉是：HTML 生成时就把文字填好，浏览器拿到就是最终文本。

对初学者来说，你可以先记住它的三个优点：

1. **更利于 SEO**：搜索引擎抓取到的就是最终文本，而不是需要等待客户端 JS 才出现的文字。
2. **首屏更稳**：页面关键内容不依赖客户端脚本执行，网络差时也更容易“先看到内容”。
3. **更少的客户端负担**：如果一个页面不需要交互，你甚至可以完全不写客户端组件。

在代码层面，`getTranslations('HomePage')` 会返回一个 `t` 函数；`t('title')` 会去当前语言的 messages 里找 `HomePage.title`。如果 key 写错或缺失，开发环境通常会报错，这反而是好事：它能让你尽早发现漏翻译的问题。

**文件路径**：`app/[locale]/page.tsx`

```tsx
import {getTranslations} from 'next-intl/server';
import NavBar from '../../components/NavBar';
import LanguageSwitcher from '../../components/LanguageSwitcher';

export default async function HomePage() {
  const t = await getTranslations('HomePage');

  return (
    <main style={{padding: 24}}>
      <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
        <NavBar />
        <LanguageSwitcher />
      </div>
      <h1 style={{fontSize: 32, marginTop: 24}}>{t('title')}</h1>
      <p style={{fontSize: 18, marginTop: 8}}>{t('subtitle')}</p>
    </main>
  );
}
```

**文件路径**：`app/[locale]/about/page.tsx`

```tsx
import {getTranslations} from 'next-intl/server';

export default async function AboutPage() {
  const t = await getTranslations('Navigation');

  return (
    <main style={{padding: 24}}>
      <h1 style={{fontSize: 28}}>{t('about')}</h1>
      <p style={{marginTop: 12}}>This is a simple about page.</p>
    </main>
  );
}
```

### 5.2 客户端组件翻译：`useTranslations`

客户端组件常见在导航、按钮、表单等交互区域。

客户端翻译有两个“必备前提”，初学者最好在脑子里形成条件反射：

1. 文件顶部需要 `'use client'`，否则 React 不允许你在组件里用 hook（比如 `useTranslations()`）。
2. 组件必须位于 `NextIntlClientProvider` 的包裹范围内，否则 hook 找不到上下文。

本课里我们还做了一个实用的工程化处理：用 `next-intl/navigation` 生成“带语言意识”的 `Link` 与路由 hook。这样你写 `href="/about"` 时，它会自动补上当前语言前缀，避免你手动拼 `/zh/about` 或 `/en/about`。

**文件路径**：`i18n/navigation.ts`

```ts
import {createNavigation} from 'next-intl/navigation';
import {routing} from './routing';

export const {Link, redirect, usePathname, useRouter} =
  createNavigation(routing);
```

**文件路径**：`components/NavBar.tsx`

```tsx
'use client';

import {useTranslations} from 'next-intl';
import {Link} from '../i18n/navigation';

export default function NavBar() {
  const t = useTranslations('Navigation');

  return (
    <nav style={{display: 'flex', gap: 12}}>
      <Link href="/">{t('home')}</Link>
      <Link href="/about">{t('about')}</Link>
    </nav>
  );
}
```

**文件路径**：`components/LanguageSwitcher.tsx`

```tsx
'use client';

import {useLocale, useTranslations} from 'next-intl';
import {usePathname, useRouter} from '../i18n/navigation';

export default function LanguageSwitcher() {
  const t = useTranslations('LanguageSwitcher');
  const locale = useLocale();
  const router = useRouter();
  const pathname = usePathname();

  return (
    <label style={{display: 'flex', gap: 8, alignItems: 'center'}}>
      <span>{t('label')}</span>
      <select
        onChange={(e) => router.replace(pathname, {locale: e.target.value as any})}
        defaultValue={locale}
      >
        <option value="zh">{t('zh')}</option>
        <option value="en">{t('en')}</option>
      </select>
    </label>
  );
}
```

此时你访问 `/zh` 是中文、访问 `/en` 是英文，并且语言切换会尽量保持当前路径不变。

**如何验证（建议你做一遍）**：

1. 访问 `http://localhost:3000/zh`
2. 点击导航里的“关于”，预期跳到 `http://localhost:3000/zh/about`
3. 在 about 页面切换语言为 English，预期跳到 `http://localhost:3000/en/about`
4. 再切回中文，预期回到 `http://localhost:3000/zh/about`

---

## 六、SEO：`hreflang` 与多语言 sitemap（最小实现）

### 6.1 `hreflang` 是什么，为什么需要它

`hreflang` 用来告诉搜索引擎：同一页面有不同语言版本。它常见目标是：

1. **明确目标受众**：告诉 Google 等搜索引擎，这是给哪种语言/地区用户看的页面。
2. **避免重复内容惩罚**：不同语言版本内容相似时，避免被误判为重复内容。

在 Next.js Metadata API 中，配置 `alternates` 后，会在 `<head>` 自动生成 `<link rel="alternate" hreflang="..." ... />`。

你可以把 `hreflang` 的价值理解成一句话：**告诉搜索引擎“这不是重复页面，这是同一页面的不同语言版本”**。

对初学者来说，先记住两个实践要点就够了：

1. **语言之间要互相指向**：中文页要指向英文页，英文页也要指向中文页。
2. **生产环境建议用绝对地址**：示例里为了简单写了相对路径或本地地址；真正上线时，建议用你的站点域名（例如 `https://example.com/zh`），避免搜索引擎无法正确识别。

**文件路径**：`app/[locale]/layout.tsx`（在已有 Layout 基础上补充 `generateMetadata`）

```tsx
import {NextIntlClientProvider} from 'next-intl';
import {getMessages} from 'next-intl/server';
import type {ReactNode} from 'react';

export async function generateMetadata({params}: {params: {locale: string}}) {
  const {locale} = params;

  return {
    alternates: {
      languages: {
        zh: '/zh',
        en: '/en'
      }
    },
    title: locale === 'zh' ? '我的博客' : 'My Blog'
  };
}

export default async function LocaleLayout({
  children,
  params
}: {
  children: ReactNode;
  params: {locale: string};
}) {
  const {locale} = params;
  const messages = await getMessages();

  return (
    <html lang={locale}>
      <body>
        <NextIntlClientProvider messages={messages}>
          {children}
        </NextIntlClientProvider>
      </body>
    </html>
  );
}
```

### 6.2 多语言 sitemap（最小实现）

**文件路径**：`app/sitemap.ts`

```ts
import type {MetadataRoute} from 'next';

export default function sitemap(): MetadataRoute.Sitemap {
  const baseUrl = 'http://localhost:3000';

  const pages = ['', '/about'];
  const locales = ['zh', 'en'];

  return locales.flatMap((locale) =>
    pages.map((p) => ({
      url: `${baseUrl}/${locale}${p}`,
      lastModified: new Date()
    }))
  );
}
```

真实项目里，页面列表往往来自 CMS/数据库，但拼接规律是一致的：`baseUrl + locale + path`。

**如何验证（建议你做一遍）**：

1. 启动项目后访问 `http://localhost:3000/sitemap.xml`
2. 你应该能看到包含 `/zh` 与 `/en` 的站点地图输出
3. 如果 404，检查文件名是否为 `app/sitemap.ts`，并确认是默认导出 `sitemap()` 函数

---

## 七、性能：翻译文件变大后，怎么避免“越做越慢”

初学阶段最简单的做法，是在 Layout 中把 `getMessages()` 拿到的所有文案都注入给客户端。它很省心，也最不容易出错；但当翻译文件变大时，性能问题会慢慢显现出来。

你可以把问题理解成“体积问题”：

1. `NextIntlClientProvider` 会把你传进去的 `messages` 序列化并传给浏览器。
2. 如果你每次都把整份 messages 注入进去，那用户即使只浏览首页，也会下载很多根本用不到的文案。
3. 文案越多，首屏传输越大，客户端解析越慢，最终体验就会变差。

所以更稳的策略是：**按命名空间拆分文案，并且客户端只注入“用得上的那部分”**。你不需要一开始就做到极致，但至少要知道这条路怎么走。

更稳的策略是：按命名空间拆分文案，并且客户端只注入“用得上的那部分”。

### 7.1 工具函数：按命名空间挑选 messages

**文件路径**：`i18n/pick.ts`

```ts
import type {AbstractIntlMessages} from 'next-intl';

export function pickMessages(
  messages: AbstractIntlMessages,
  namespaces: Array<keyof AbstractIntlMessages | string>
) {
  const picked: AbstractIntlMessages = {};

  for (const ns of namespaces) {
    const value = (messages as any)[ns];
    if (value) (picked as any)[ns] = value;
  }

  return picked;
}
```

这里的 `pickMessages` 只做一件事：从 messages 的顶层对象里，挑出你指定的命名空间（例如只挑 `Navigation` 和 `LanguageSwitcher`）。它不做深拷贝优化，也不处理复杂路径；但对初学者来说，它简单、直观、好调试，已经足够解决“把全部翻译塞进浏览器”的问题。

你可以用一个简单的直觉来理解它：

- 根布局里只放“每个页面都会出现的客户端组件”（例如导航、语言切换）
- 某个页面如果有专属的客户端组件，就在页面里额外包一层 Provider，只注入它需要的命名空间

### 7.2 根布局：只注入全局共享命名空间

把“导航栏 + 语言切换器”放进 Layout，这样它们在每个页面都可用，但只需要注入 `Navigation` 和 `LanguageSwitcher`。

**文件路径**：`app/[locale]/layout.tsx`

```tsx
import {NextIntlClientProvider} from 'next-intl';
import {getMessages} from 'next-intl/server';
import type {ReactNode} from 'react';
import NavBar from '../../components/NavBar';
import LanguageSwitcher from '../../components/LanguageSwitcher';
import {pickMessages} from '../../i18n/pick';

export default async function LocaleLayout({
  children,
  params
}: {
  children: ReactNode;
  params: {locale: string};
}) {
  const {locale} = params;
  const messages = await getMessages();

  const sharedMessages = pickMessages(messages, ['Navigation', 'LanguageSwitcher']);

  return (
    <html lang={locale}>
      <body style={{padding: 24}}>
        <NextIntlClientProvider messages={sharedMessages}>
          <header
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center'
            }}
          >
            <NavBar />
            <LanguageSwitcher />
          </header>

          {children}
        </NextIntlClientProvider>
      </body>
    </html>
  );
}
```

### 7.3 页面级 Provider：只为当前页面注入 `HomePage`

如果首页里有客户端组件需要 `HomePage`，就只在首页额外注入 `HomePage` 命名空间。

**文件路径**：`components/HomeHero.tsx`

```tsx
'use client';

import {useTranslations} from 'next-intl';

export default function HomeHero() {
  const t = useTranslations('HomePage');

  return (
    <section style={{marginTop: 24}}>
      <h1 style={{fontSize: 32}}>{t('title')}</h1>
      <p style={{fontSize: 18, marginTop: 8}}>{t('subtitle')}</p>
    </section>
  );
}
```

**文件路径**：`app/[locale]/page.tsx`

```tsx
import {NextIntlClientProvider} from 'next-intl';
import {getMessages} from 'next-intl/server';
import HomeHero from '../../components/HomeHero';
import {pickMessages} from '../../i18n/pick';

export default async function HomePage() {
  const messages = await getMessages();
  const pageMessages = pickMessages(messages, ['HomePage']);

  return (
    <NextIntlClientProvider messages={pageMessages}>
      <HomeHero />
    </NextIntlClientProvider>
  );
}
```

### 7.4 官方延伸阅读（性能与最佳实践）

- next-intl Messages：`https://next-intl.dev/docs/usage/messages`
- next-intl Messages 配置：`https://next-intl.dev/docs/usage/configuration#messages`
- next-intl useExtracted（实验性）：`https://next-intl.dev/docs/usage/extraction`
- next-intl Routing 配置：`https://next-intl.dev/docs/routing/configuration`
- Next.js Internationalization 指南：`https://nextjs.org/docs/app/guides/internationalization`

---

## 八、开发效率：IDE i18n 插件建议

真实项目里最耗时间的不是写 `t('xxx')`，而是确认 key 对应的文案、以及保证不同语言都补齐了翻译。推荐 VS Code 插件 **i18n Ally**，它对初学者最实用的点包括：

- 在代码旁直接显示当前语言的文案，减少来回打开 JSON 的次数
- 输入 key 时提供提示，减少拼写错误（例如把 `subtitle` 写成 `subTitle`）
- 检测缺失翻译：你新增了一个 key，但忘了给英文补齐，它会提醒你

**文件路径**：`.vscode/settings.json`

```json
{
  "i18n-ally.localesPaths": ["messages"],
  "i18n-ally.keystyle": "nested",
  "i18n-ally.displayLanguage": "zh"
}
```

---

## 附录

### 附录 A：从零本地跑通（初学者操作清单）

如果你是第一次做 i18n，建议按下面顺序操作，每一步都确认结果正确再进行下一步：

1. 初始化项目（或确认已有 App Router 项目）
2. 安装 `next-intl` 并配置 `next.config.*`，重启 `npm run dev`
3. 创建 `messages/zh.json` 与 `messages/en.json`
4. 创建 `i18n/routing.ts`、`i18n/request.ts`、`i18n/navigation.ts`
5. 创建 `middleware.ts`，验证 `/` 会跳转到 `/zh`
6. 创建 `app/[locale]/layout.tsx` 注入 `NextIntlClientProvider`
7. 创建 `app/[locale]/page.tsx` 与 `app/[locale]/about/page.tsx`
8. 创建 `components/NavBar.tsx` 与 `components/LanguageSwitcher.tsx`，验证路由与切换
9. 可选：加入 SEO（`generateMetadata` 的 `alternates`）与 `app/sitemap.ts`

从零创建项目的最小命令：

```bash
npx create-next-app@latest next-intl-demo --ts --app --eslint
cd next-intl-demo
npm install next-intl
npm run dev
```

本地验证入口：

- `http://localhost:3000`（预期跳转到 `/zh`）
- `http://localhost:3000/en`
- `http://localhost:3000/zh/about`
- `http://localhost:3000/en/about`
- `http://localhost:3000/sitemap.xml`（如果你创建了 `app/sitemap.ts`）

---

### 附录 B：常见问题排查（初学者高频）

**访问 `/en` 直接 404**
先确认目录结构存在 `app/[locale]/page.tsx`，因为 `/en` 是靠 `[locale]` 匹配出来的。然后检查 `i18n/routing.ts` 的 `locales` 是否包含 `en`，以及 `messages/en.json` 是否存在且 JSON 格式正确。

**客户端组件报错找不到翻译上下文**
这类错误通常意味着：组件不在 `NextIntlClientProvider` 范围内。检查 `app/[locale]/layout.tsx` 是否把 `children` 放进了 Provider；同时确认组件文件顶部有 `'use client'`（只有需要 hook 的组件才写）。

**语言切换后没有保持当前页面**
确认你使用的是 `next-intl/navigation` 生成的 `usePathname` 与 `useRouter`，并且切换逻辑是 `router.replace(pathname, {locale: ...})` 这种“保持 pathname 不变，只切换 locale”的写法。

**改了 `next.config.*` 但感觉没生效**
修改 `next.config.*` 后建议重启开发服务器；同时检查项目实际使用的是 `next.config.mjs` 还是 `next.config.js`，两者的导出方式不同（ESM vs CommonJS）。

**访问不支持的语言没有 404**
检查 `i18n/request.ts` 是否对非法 locale 调用了 `notFound()`；同时检查 `routing.locales` 是否不小心包含了你不想开放的语言。