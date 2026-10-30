import type { GetServerSideProps, NextPage } from "next";
import Head from "next/head";
import Link from "next/link";
import Layout from "@/components/layout/Layout";
import styles from "@/styles/Home.module.css";
import { APP_NAME, AUTH_TOKEN_KEY } from "@/utils/constants";
import type { User } from "@/types";
import { getUserFromToken } from "@/lib/mockStore";
import { useAuth } from "@/hooks/useAuth";

interface ProfileProps {
  user: User | null;
}

const ProfilePage: NextPage<ProfileProps> = ({ user: ssrUser }) => {
  const { user: clientUser } = useAuth();
  const activeUser = ssrUser ?? clientUser;

  return (
    <>
      <Head>
        <title>Profile | {APP_NAME}</title>
      </Head>
      <Layout>
        <div className={styles.page}>
          <h1>Profile</h1>
          {activeUser ? (
            <>
              <p>Name: {activeUser.name}</p>
              <p>Email: {activeUser.email}</p>
            </>
          ) : (
            <p>
              No user loaded. <Link href="/login">Sign in</Link> to view your profile.
            </p>
          )}
        </div>
      </Layout>
    </>
  );
};

export const getServerSideProps: GetServerSideProps<ProfileProps> = async ({ req }) => {
  const token = req.cookies[AUTH_TOKEN_KEY];
  const user = token ? getUserFromToken(token) : null;

  return {
    props: {
      user,
    },
  };
};

export default ProfilePage;
