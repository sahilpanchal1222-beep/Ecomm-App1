import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import path from 'path';
import { config } from 'dotenv';

config({ path: path.resolve(process.cwd(), ".env") });

const dbType = process.env.DATABASE_TYPE || "sqlite";
const dbUrl = process.env.DATABASE_URL || "file:./dev.db";

let prismaClientSingleton: () => PrismaClient;

if (dbType === "postgresql") {
  const pool = new Pool({ connectionString: dbUrl });
  const adapter = new PrismaPg(pool);

  prismaClientSingleton = () => {
    return new PrismaClient({ adapter });
  };
} else {
  const { PrismaLibSql } = require('@prisma/adapter-libsql');
  const { createClient } = require('@libsql/client');

  const libsql = createClient({ url: dbUrl });
  const adapter = new PrismaLibSql(libsql);

  prismaClientSingleton = () => {
    return new PrismaClient({ adapter });
  };
}

declare global {
  var prisma: undefined | ReturnType<typeof prismaClientSingleton>;
}

const prisma = globalThis.prisma ?? prismaClientSingleton();

export default prisma;

if (process.env.NODE_ENV !== 'production') globalThis.prisma = prisma;
