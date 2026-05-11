


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."get_my_accepted_group_ids"() RETURNS SETOF "uuid"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select group_id
  from family_group_members
  where user_id = auth.uid() and status = 'accepted'
$$;


ALTER FUNCTION "public"."get_my_accepted_group_ids"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."touch_list_on_item_change"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$                                                                                                                                                                                
  BEGIN                                           
    UPDATE shopping_lists                                                                                                                                                                              
    SET updated_at = NOW()                            
    WHERE id = COALESCE(NEW.list_id, OLD.list_id);
    RETURN COALESCE(NEW, OLD);                                                                                                                                                                         
  END;
  $$;


ALTER FUNCTION "public"."touch_list_on_item_change"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."categories" (
    "id" "uuid" NOT NULL,
    "owner_id" "uuid" NOT NULL,
    "family_group_id" "uuid",
    "name" "text" NOT NULL,
    "color_value" bigint NOT NULL,
    "sort_order" integer DEFAULT 0 NOT NULL,
    "is_default" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."family_group_members" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "group_id" "uuid" NOT NULL,
    "user_id" "uuid",
    "email" "text" NOT NULL,
    "role" "text" DEFAULT 'member'::"text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "invited_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE ONLY "public"."family_group_members" REPLICA IDENTITY FULL;


ALTER TABLE "public"."family_group_members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."family_groups" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "owner_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."family_groups" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."shopping_items" (
    "id" "uuid" NOT NULL,
    "list_id" "uuid" NOT NULL,
    "owner_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "quantity" double precision DEFAULT 1 NOT NULL,
    "unit" "text" DEFAULT 'Stk.'::"text" NOT NULL,
    "category_id" "uuid" NOT NULL,
    "is_checked" boolean DEFAULT false NOT NULL,
    "image_path" "text",
    "created_at" timestamp with time zone NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."shopping_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."shopping_lists" (
    "id" "uuid" NOT NULL,
    "owner_id" "uuid" NOT NULL,
    "family_group_id" "uuid",
    "name" "text" NOT NULL,
    "is_default" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."shopping_lists" OWNER TO "postgres";


ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."family_group_members"
    ADD CONSTRAINT "family_group_members_group_id_email_key" UNIQUE ("group_id", "email");



ALTER TABLE ONLY "public"."family_group_members"
    ADD CONSTRAINT "family_group_members_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."family_groups"
    ADD CONSTRAINT "family_groups_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."shopping_items"
    ADD CONSTRAINT "shopping_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."shopping_lists"
    ADD CONSTRAINT "shopping_lists_pkey" PRIMARY KEY ("id");



CREATE OR REPLACE TRIGGER "shopping_items_touch_list" AFTER INSERT OR DELETE OR UPDATE ON "public"."shopping_items" FOR EACH ROW EXECUTE FUNCTION "public"."touch_list_on_item_change"();



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_family_group_id_fkey" FOREIGN KEY ("family_group_id") REFERENCES "public"."family_groups"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."family_group_members"
    ADD CONSTRAINT "family_group_members_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "public"."family_groups"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."family_group_members"
    ADD CONSTRAINT "family_group_members_invited_by_fkey" FOREIGN KEY ("invited_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."family_group_members"
    ADD CONSTRAINT "family_group_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."family_groups"
    ADD CONSTRAINT "family_groups_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."shopping_items"
    ADD CONSTRAINT "shopping_items_list_id_fkey" FOREIGN KEY ("list_id") REFERENCES "public"."shopping_lists"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."shopping_items"
    ADD CONSTRAINT "shopping_items_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."shopping_lists"
    ADD CONSTRAINT "shopping_lists_family_group_id_fkey" FOREIGN KEY ("family_group_id") REFERENCES "public"."family_groups"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."shopping_lists"
    ADD CONSTRAINT "shopping_lists_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "auth"."users"("id");



ALTER TABLE "public"."categories" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "delete_group" ON "public"."family_groups" FOR DELETE USING (("owner_id" = "auth"."uid"()));



CREATE POLICY "delete_items" ON "public"."shopping_items" FOR DELETE USING ((("owner_id" = "auth"."uid"()) OR ("list_id" IN ( SELECT "shopping_lists"."id"
   FROM "public"."shopping_lists"
  WHERE ("shopping_lists"."family_group_id" IN ( SELECT "public"."get_my_accepted_group_ids"() AS "get_my_accepted_group_ids"))))));



CREATE POLICY "delete_member" ON "public"."family_group_members" FOR DELETE USING ((("user_id" = "auth"."uid"()) OR ("group_id" IN ( SELECT "family_groups"."id"
   FROM "public"."family_groups"
  WHERE ("family_groups"."owner_id" = "auth"."uid"())))));



ALTER TABLE "public"."family_group_members" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."family_groups" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "insert_group" ON "public"."family_groups" FOR INSERT WITH CHECK (("owner_id" = "auth"."uid"()));



CREATE POLICY "insert_invite" ON "public"."family_group_members" FOR INSERT WITH CHECK (("group_id" IN ( SELECT "family_groups"."id"
   FROM "public"."family_groups"
  WHERE ("family_groups"."owner_id" = "auth"."uid"()))));



CREATE POLICY "insert_items" ON "public"."shopping_items" FOR INSERT WITH CHECK ((("owner_id" = "auth"."uid"()) OR ("list_id" IN ( SELECT "shopping_lists"."id"
   FROM "public"."shopping_lists"
  WHERE ("shopping_lists"."family_group_id" IN ( SELECT "public"."get_my_accepted_group_ids"() AS "get_my_accepted_group_ids"))))));



CREATE POLICY "select_items" ON "public"."shopping_items" FOR SELECT USING ((("owner_id" = "auth"."uid"()) OR ("list_id" IN ( SELECT "shopping_lists"."id"
   FROM "public"."shopping_lists"
  WHERE ("shopping_lists"."family_group_id" IN ( SELECT "public"."get_my_accepted_group_ids"() AS "get_my_accepted_group_ids"))))));



CREATE POLICY "select_lists" ON "public"."shopping_lists" FOR SELECT USING ((("owner_id" = "auth"."uid"()) OR ("family_group_id" IN ( SELECT "public"."get_my_accepted_group_ids"() AS "get_my_accepted_group_ids"))));



CREATE POLICY "select_members" ON "public"."family_group_members" FOR SELECT USING ((("user_id" = "auth"."uid"()) OR ("email" = "auth"."email"()) OR ("group_id" IN ( SELECT "public"."get_my_accepted_group_ids"() AS "get_my_accepted_group_ids")) OR ("group_id" IN ( SELECT "family_groups"."id"
   FROM "public"."family_groups"
  WHERE ("family_groups"."owner_id" = "auth"."uid"())))));



CREATE POLICY "select_my_group" ON "public"."family_groups" FOR SELECT USING (
  ("owner_id" = "auth"."uid"())
  OR ("id" IN ( SELECT "public"."get_my_accepted_group_ids"() AS "get_my_accepted_group_ids"))
  OR ("id" IN (
    SELECT "fgm"."group_id"
    FROM "public"."family_group_members" "fgm"
    WHERE ("fgm"."email" = ( SELECT "u"."email" FROM "auth"."users" "u" WHERE ("u"."id" = "auth"."uid"())))
      AND ("fgm"."status" = 'pending')
  ))
);



ALTER TABLE "public"."shopping_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."shopping_lists" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "update_items" ON "public"."shopping_items" FOR UPDATE USING ((("owner_id" = "auth"."uid"()) OR ("list_id" IN ( SELECT "shopping_lists"."id"
   FROM "public"."shopping_lists"
  WHERE ("shopping_lists"."family_group_id" IN ( SELECT "public"."get_my_accepted_group_ids"() AS "get_my_accepted_group_ids"))))));



CREATE POLICY "update_member" ON "public"."family_group_members" FOR UPDATE USING ((("user_id" = "auth"."uid"()) OR ("email" = "auth"."email"()) OR ("group_id" IN ( SELECT "family_groups"."id"
   FROM "public"."family_groups"
  WHERE ("family_groups"."owner_id" = "auth"."uid"())))));



CREATE POLICY "users manage own categories" ON "public"."categories" USING (("owner_id" = "auth"."uid"())) WITH CHECK (("owner_id" = "auth"."uid"()));



CREATE POLICY "users manage own items" ON "public"."shopping_items" USING (("owner_id" = "auth"."uid"())) WITH CHECK (("owner_id" = "auth"."uid"()));



CREATE POLICY "users manage own lists" ON "public"."shopping_lists" USING (("owner_id" = "auth"."uid"())) WITH CHECK (("owner_id" = "auth"."uid"()));





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."family_group_members";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."shopping_items";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."shopping_lists";



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

























































































































































GRANT ALL ON FUNCTION "public"."get_my_accepted_group_ids"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_my_accepted_group_ids"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_my_accepted_group_ids"() TO "service_role";



GRANT ALL ON FUNCTION "public"."touch_list_on_item_change"() TO "anon";
GRANT ALL ON FUNCTION "public"."touch_list_on_item_change"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."touch_list_on_item_change"() TO "service_role";


















GRANT ALL ON TABLE "public"."categories" TO "anon";
GRANT ALL ON TABLE "public"."categories" TO "authenticated";
GRANT ALL ON TABLE "public"."categories" TO "service_role";



GRANT ALL ON TABLE "public"."family_group_members" TO "anon";
GRANT ALL ON TABLE "public"."family_group_members" TO "authenticated";
GRANT ALL ON TABLE "public"."family_group_members" TO "service_role";



GRANT ALL ON TABLE "public"."family_groups" TO "anon";
GRANT ALL ON TABLE "public"."family_groups" TO "authenticated";
GRANT ALL ON TABLE "public"."family_groups" TO "service_role";



GRANT ALL ON TABLE "public"."shopping_items" TO "anon";
GRANT ALL ON TABLE "public"."shopping_items" TO "authenticated";
GRANT ALL ON TABLE "public"."shopping_items" TO "service_role";



GRANT ALL ON TABLE "public"."shopping_lists" TO "anon";
GRANT ALL ON TABLE "public"."shopping_lists" TO "authenticated";
GRANT ALL ON TABLE "public"."shopping_lists" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































