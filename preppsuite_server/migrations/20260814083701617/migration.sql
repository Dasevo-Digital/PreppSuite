BEGIN;

--
-- Function: gen_random_uuid_v7()
-- Source: https://gist.github.com/kjmph/5bd772b2c2df145aa645b837da7eca74
-- License: MIT (copyright notice included on the generator source code).
--
create or replace function gen_random_uuid_v7()
returns uuid
as $$
begin
  -- use random v4 uuid as starting point (which has the same variant we need)
  -- then overlay timestamp
  -- then set version 7 by flipping the 2 and 1 bit in the version 4 string
  return encode(
    set_bit(
      set_bit(
        overlay(uuid_send(gen_random_uuid())
                placing substring(int8send(floor(extract(epoch from clock_timestamp()) * 1000)::bigint) from 3)
                from 1 for 6
        ),
        52, 1
      ),
      53, 1
    ),
    'hex')::uuid;
end
$$
language plpgsql
volatile;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "inventory_item" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "householdId" uuid NOT NULL,
    "clientId" uuid NOT NULL,
    "name" text NOT NULL,
    "category" text NOT NULL,
    "barcode" text,
    "offProductId" text,
    "quantity" double precision NOT NULL,
    "unit" text NOT NULL,
    "storageLocation" text NOT NULL,
    "expirationDate" timestamp without time zone,
    "minQuantity" double precision,
    "notes" text,
    "updatedAt" timestamp without time zone NOT NULL,
    "deletedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "inventory_item_household_client_id" ON "inventory_item" USING btree ("householdId", "clientId");
CREATE INDEX "inventory_item_household_updated_at" ON "inventory_item" USING btree ("householdId", "updatedAt");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "inventory_item"
    ADD CONSTRAINT "inventory_item_fk_0"
    FOREIGN KEY("householdId")
    REFERENCES "household"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR preppsuite
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('preppsuite', '20260814083701617', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260814083701617', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260129181112269', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129181112269', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260213194423028', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260213194423028', "timestamp" = now();


COMMIT;
