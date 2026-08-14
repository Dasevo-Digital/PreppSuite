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
CREATE TABLE "budget_entry" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "clientId" uuid NOT NULL,
    "householdId" uuid NOT NULL,
    "label" text NOT NULL,
    "amountCents" bigint NOT NULL,
    "currency" text NOT NULL,
    "category" text NOT NULL,
    "purchaseDate" timestamp without time zone,
    "linkedInventoryItemId" uuid,
    "updatedAt" timestamp without time zone NOT NULL,
    "deletedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "budget_entry_household_client_id" ON "budget_entry" USING btree ("householdId", "clientId");
CREATE INDEX "budget_entry_household_updated_at" ON "budget_entry" USING btree ("householdId", "updatedAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "checklist_item" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "clientId" uuid NOT NULL,
    "householdId" uuid,
    "templateId" uuid NOT NULL,
    "title" text NOT NULL,
    "targetQuantity" double precision,
    "isChecked" boolean NOT NULL,
    "linkedInventoryItemId" uuid,
    "sortOrder" bigint NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deletedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "checklist_item_household_client_id" ON "checklist_item" USING btree ("householdId", "clientId");
CREATE INDEX "checklist_item_household_updated_at" ON "checklist_item" USING btree ("householdId", "updatedAt");
CREATE INDEX "checklist_item_template" ON "checklist_item" USING btree ("templateId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "checklist_template" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "clientId" uuid NOT NULL,
    "householdId" uuid,
    "title" text NOT NULL,
    "category" text NOT NULL,
    "isBuiltIn" boolean NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deletedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "checklist_template_household_client_id" ON "checklist_template" USING btree ("householdId", "clientId");
CREATE INDEX "checklist_template_household_updated_at" ON "checklist_template" USING btree ("householdId", "updatedAt");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "budget_entry"
    ADD CONSTRAINT "budget_entry_fk_0"
    FOREIGN KEY("householdId")
    REFERENCES "household"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "checklist_item"
    ADD CONSTRAINT "checklist_item_fk_0"
    FOREIGN KEY("householdId")
    REFERENCES "household"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "checklist_item"
    ADD CONSTRAINT "checklist_item_fk_1"
    FOREIGN KEY("templateId")
    REFERENCES "checklist_template"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "checklist_template"
    ADD CONSTRAINT "checklist_template_fk_0"
    FOREIGN KEY("householdId")
    REFERENCES "household"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR preppsuite
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('preppsuite', '20260814090615073', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260814090615073', "timestamp" = now();

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
