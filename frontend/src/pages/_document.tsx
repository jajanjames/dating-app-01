import { Html, Head, Main, NextScript } from "next/document";

export default function Document() {
  return (
    <Html lang="en">
      <Head>
        <meta name="description" content="JDATE full-stack web application and API platform" />
        <meta property="og:title" content="JDATE" />
        <meta property="og:description" content="JDATE full-stack web application and API platform" />
      </Head>
      <body>
        <Main />
        <NextScript />
      </body>
    </Html>
  );
}
