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

--
-- Name: vector; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;


--
-- Name: EXTENSION vector; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION vector IS 'vector data type and ivfflat and hnsw access methods';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: conversation_memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversation_memberships (
    id bigint NOT NULL,
    conversation_id bigint NOT NULL,
    participant_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: conversation_memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conversation_memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversation_memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conversation_memberships_id_seq OWNED BY public.conversation_memberships.id;


--
-- Name: conversations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversations (
    id bigint NOT NULL,
    subject character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: conversations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conversations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conversations_id_seq OWNED BY public.conversations.id;


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groups (
    id bigint NOT NULL,
    name character varying NOT NULL,
    group_type character varying NOT NULL,
    slug character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.groups_id_seq OWNED BY public.groups.id;


--
-- Name: memories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.memories (
    id bigint NOT NULL,
    participant_id bigint NOT NULL,
    scope character varying NOT NULL,
    agent_class character varying,
    content text NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    embedding public.vector
);


--
-- Name: memories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.memories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: memories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.memories_id_seq OWNED BY public.memories.id;


--
-- Name: message_parts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.message_parts (
    id bigint NOT NULL,
    message_id bigint NOT NULL,
    content_type character varying NOT NULL,
    channel_hint character varying,
    body text,
    "position" integer DEFAULT 0,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: message_parts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.message_parts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_parts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.message_parts_id_seq OWNED BY public.message_parts.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id bigint NOT NULL,
    subject character varying,
    conversation_id bigint,
    from_id bigint NOT NULL,
    to_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    flagged boolean DEFAULT false NOT NULL
);


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.participants (
    id bigint NOT NULL,
    name character varying NOT NULL,
    type character varying NOT NULL,
    slug character varying NOT NULL,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    token character varying,
    agent_class character varying,
    state character varying DEFAULT 'awake'::character varying,
    emotion_parameters jsonb DEFAULT '{"happy": 75, "anxious": 10, "focused": 80, "exhausted": 0, "irritated": 10}'::jsonb,
    suspicion_count integer DEFAULT 0 NOT NULL
);


--
-- Name: participants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.participants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.participants_id_seq OWNED BY public.participants.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: security_passes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.security_passes (
    id bigint NOT NULL,
    participant_id bigint NOT NULL,
    group_id bigint NOT NULL,
    capabilities jsonb DEFAULT '[]'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: security_passes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.security_passes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: security_passes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.security_passes_id_seq OWNED BY public.security_passes.id;


--
-- Name: conversation_memberships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_memberships ALTER COLUMN id SET DEFAULT nextval('public.conversation_memberships_id_seq'::regclass);


--
-- Name: conversations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations ALTER COLUMN id SET DEFAULT nextval('public.conversations_id_seq'::regclass);


--
-- Name: groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups ALTER COLUMN id SET DEFAULT nextval('public.groups_id_seq'::regclass);


--
-- Name: memories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memories ALTER COLUMN id SET DEFAULT nextval('public.memories_id_seq'::regclass);


--
-- Name: message_parts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_parts ALTER COLUMN id SET DEFAULT nextval('public.message_parts_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: participants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.participants ALTER COLUMN id SET DEFAULT nextval('public.participants_id_seq'::regclass);


--
-- Name: security_passes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.security_passes ALTER COLUMN id SET DEFAULT nextval('public.security_passes_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: conversation_memberships conversation_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_memberships
    ADD CONSTRAINT conversation_memberships_pkey PRIMARY KEY (id);


--
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (id);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: memories memories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memories
    ADD CONSTRAINT memories_pkey PRIMARY KEY (id);


--
-- Name: message_parts message_parts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_parts
    ADD CONSTRAINT message_parts_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: participants participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.participants
    ADD CONSTRAINT participants_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: security_passes security_passes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.security_passes
    ADD CONSTRAINT security_passes_pkey PRIMARY KEY (id);


--
-- Name: index_conversation_memberships_on_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversation_memberships_on_conversation_id ON public.conversation_memberships USING btree (conversation_id);


--
-- Name: index_conversation_memberships_on_participant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversation_memberships_on_participant_id ON public.conversation_memberships USING btree (participant_id);


--
-- Name: index_groups_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_groups_on_slug ON public.groups USING btree (slug);


--
-- Name: index_memories_on_participant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_memories_on_participant_id ON public.memories USING btree (participant_id);


--
-- Name: index_message_parts_on_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_message_parts_on_message_id ON public.message_parts USING btree (message_id);


--
-- Name: index_messages_on_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_conversation_id ON public.messages USING btree (conversation_id);


--
-- Name: index_messages_on_from_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_from_id ON public.messages USING btree (from_id);


--
-- Name: index_messages_on_to_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_to_id ON public.messages USING btree (to_id);


--
-- Name: index_participants_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_participants_on_slug ON public.participants USING btree (slug);


--
-- Name: index_participants_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_participants_on_token ON public.participants USING btree (token);


--
-- Name: index_security_passes_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_security_passes_on_group_id ON public.security_passes USING btree (group_id);


--
-- Name: index_security_passes_on_participant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_security_passes_on_participant_id ON public.security_passes USING btree (participant_id);


--
-- Name: security_passes fk_rails_0efa41916d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.security_passes
    ADD CONSTRAINT fk_rails_0efa41916d FOREIGN KEY (participant_id) REFERENCES public.participants(id);


--
-- Name: message_parts fk_rails_1d227a7141; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_parts
    ADD CONSTRAINT fk_rails_1d227a7141 FOREIGN KEY (message_id) REFERENCES public.messages(id);


--
-- Name: messages fk_rails_2bcf7eed31; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_rails_2bcf7eed31 FOREIGN KEY (from_id) REFERENCES public.participants(id);


--
-- Name: messages fk_rails_5eb9eebc29; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_rails_5eb9eebc29 FOREIGN KEY (to_id) REFERENCES public.participants(id);


--
-- Name: conversation_memberships fk_rails_67a38991f3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_memberships
    ADD CONSTRAINT fk_rails_67a38991f3 FOREIGN KEY (conversation_id) REFERENCES public.conversations(id);


--
-- Name: messages fk_rails_7f927086d2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_rails_7f927086d2 FOREIGN KEY (conversation_id) REFERENCES public.conversations(id);


--
-- Name: conversation_memberships fk_rails_b40be6fc45; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_memberships
    ADD CONSTRAINT fk_rails_b40be6fc45 FOREIGN KEY (participant_id) REFERENCES public.participants(id);


--
-- Name: security_passes fk_rails_c872d7c909; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.security_passes
    ADD CONSTRAINT fk_rails_c872d7c909 FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: memories fk_rails_fa7281a93a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memories
    ADD CONSTRAINT fk_rails_fa7281a93a FOREIGN KEY (participant_id) REFERENCES public.participants(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260317200002'),
('20260317200001'),
('20260317162542'),
('20260317162541'),
('20260317162540'),
('20260317162539'),
('20260317162538'),
('20260317162533'),
('20260317162532'),
('20260317162531'),
('20260317162530'),
('20260317162526'),
('20260317162525'),
('20260317162524'),
('20260317162523');

