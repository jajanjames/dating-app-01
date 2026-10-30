import type { GetServerSideProps, NextPage } from "next";
import Head from "next/head";
import Link from "next/link";
import Layout from "@/components/layout/Layout";
import styles from "@/styles/Home.module.css";
import { APP_NAME, AUTH_TOKEN_KEY } from "@/utils/constants";
import { useAuth } from "@/hooks/useAuth";

interface DashboardProps {
  isAuthenticated: boolean;
}

const DashboardPage: NextPage<DashboardProps> = ({ isAuthenticated }) => {
  const { user } = useAuth();
  const authed = isAuthenticated || Boolean(user);

  return (
    <>
      <Head>
        <title>Dashboard | {APP_NAME}</title>
      </Head>
      <Layout>
        <div className={styles.page}>
          <h1>Dashboard</h1>
          <p>Authenticated: {String(authed)}</p>
          {user && <p>Welcome back, {user.name} ({user.email})</p>}
          {!authed && (
            <p>
              <Link href="/login">Login</Link> or <Link href="/register">Register</Link> to get started.
            </p>
          )}
        </div>
      </Layout>
    </>
  );
};

export const getServerSideProps: GetServerSideProps<DashboardProps> = async ({ req }) => {
  const token = req.cookies[AUTH_TOKEN_KEY];

  return {
    props: {
      isAuthenticated: Boolean(token),
    },
  };
};

export default DashboardPage;
