--
-- PostgreSQL database dump
--

\restrict wZ9r7OtYfbQaXmghodZKtebJJIktpZwe3OqFBmQoXas0oPzVWyiHGHCE618LTf5

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

-- Started on 2026-05-30 18:59:37

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 228 (class 1255 OID 16761)
-- Name: trigger_set_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trigger_set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.trigger_set_updated_at() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 222 (class 1259 OID 33461)
-- Name: kategori; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.kategori (
    id integer NOT NULL,
    nama character varying(100) NOT NULL,
    color character varying(10) DEFAULT '#666666'::character varying NOT NULL,
    emoji character varying(10) DEFAULT '🍽'::character varying NOT NULL
);


ALTER TABLE public.kategori OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 33460)
-- Name: kategori_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.kategori_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.kategori_id_seq OWNER TO postgres;

--
-- TOC entry 5075 (class 0 OID 0)
-- Dependencies: 221
-- Name: kategori_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.kategori_id_seq OWNED BY public.kategori.id;


--
-- TOC entry 223 (class 1259 OID 33475)
-- Name: kedai; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.kedai (
    id integer NOT NULL,
    nama character varying(150) NOT NULL,
    kelurahan_id integer NOT NULL,
    kategori_id integer NOT NULL,
    lat numeric(10,6) NOT NULL,
    lng numeric(10,6) NOT NULL,
    rating numeric(3,1) DEFAULT 0.0 NOT NULL,
    reviews integer DEFAULT 0 NOT NULL,
    status character varying(10) DEFAULT 'Buka'::character varying NOT NULL,
    jam character varying(30) NOT NULL,
    harga character varying(50) NOT NULL,
    harga_rata integer DEFAULT 0 NOT NULL,
    telp character varying(20),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT kedai_rating_check CHECK (((rating >= (0)::numeric) AND (rating <= (5)::numeric))),
    CONSTRAINT kedai_status_check CHECK (((status)::text = ANY ((ARRAY['Buka'::character varying, 'Tutup'::character varying])::text[])))
);


ALTER TABLE public.kedai OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 33511)
-- Name: kedai_foto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.kedai_foto (
    id integer NOT NULL,
    kedai_id integer NOT NULL,
    url text NOT NULL,
    urutan integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.kedai_foto OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 33510)
-- Name: kedai_foto_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.kedai_foto_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.kedai_foto_id_seq OWNER TO postgres;

--
-- TOC entry 5076 (class 0 OID 0)
-- Dependencies: 224
-- Name: kedai_foto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.kedai_foto_id_seq OWNED BY public.kedai_foto.id;


--
-- TOC entry 220 (class 1259 OID 33450)
-- Name: kelurahan; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.kelurahan (
    id integer NOT NULL,
    nama character varying(100) NOT NULL
);


ALTER TABLE public.kelurahan OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 33449)
-- Name: kelurahan_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.kelurahan_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.kelurahan_id_seq OWNER TO postgres;

--
-- TOC entry 5077 (class 0 OID 0)
-- Dependencies: 219
-- Name: kelurahan_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.kelurahan_id_seq OWNED BY public.kelurahan.id;


--
-- TOC entry 226 (class 1259 OID 33535)
-- Name: v_kedai_lengkap; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_kedai_lengkap AS
SELECT
    NULL::integer AS id,
    NULL::character varying(150) AS nama,
    NULL::character varying(100) AS kelurahan,
    NULL::character varying(100) AS kategori,
    NULL::character varying(10) AS kategori_color,
    NULL::character varying(10) AS kategori_emoji,
    NULL::double precision AS lat,
    NULL::double precision AS lng,
    NULL::double precision AS rating,
    NULL::integer AS reviews,
    NULL::character varying(10) AS status,
    NULL::character varying(30) AS jam,
    NULL::character varying(50) AS harga,
    NULL::integer AS harga_rata,
    NULL::character varying(20) AS telp,
    NULL::text[] AS foto_urls;


ALTER VIEW public.v_kedai_lengkap OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 33540)
-- Name: v_statistik; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_statistik AS
 SELECT count(*) AS total_kedai,
    count(*) FILTER (WHERE ((status)::text = 'Buka'::text)) AS total_buka,
    count(*) FILTER (WHERE ((status)::text = 'Tutup'::text)) AS total_tutup,
    count(DISTINCT kelurahan_id) AS total_kelurahan,
    round(avg(rating), 1) AS avg_rating,
    (round(avg(harga_rata)))::integer AS avg_harga
   FROM public.kedai;


ALTER VIEW public.v_statistik OWNER TO postgres;

--
-- TOC entry 4880 (class 2604 OID 33464)
-- Name: kategori id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kategori ALTER COLUMN id SET DEFAULT nextval('public.kategori_id_seq'::regclass);


--
-- TOC entry 4889 (class 2604 OID 33514)
-- Name: kedai_foto id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kedai_foto ALTER COLUMN id SET DEFAULT nextval('public.kedai_foto_id_seq'::regclass);


--
-- TOC entry 4879 (class 2604 OID 33453)
-- Name: kelurahan id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kelurahan ALTER COLUMN id SET DEFAULT nextval('public.kelurahan_id_seq'::regclass);


--
-- TOC entry 5066 (class 0 OID 33461)
-- Dependencies: 222
-- Data for Name: kategori; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.kategori (id, nama, color, emoji) FROM stdin;
1	Rumah Makan	#16a34a	🍛
2	Fast Food	#dc2626	🍔
3	Kuliner Khas Lokal	#d97706	🍲
4	Restoran	#7c3aed	🍽️
5	Cafe	#0891b2	☕
\.


--
-- TOC entry 5067 (class 0 OID 33475)
-- Dependencies: 223
-- Data for Name: kedai; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.kedai (id, nama, kelurahan_id, kategori_id, lat, lng, rating, reviews, status, jam, harga, harga_rata, telp, created_at, updated_at) FROM stdin;
3	Rumah Makan Lompoh	1	1	3.555985	98.649211	4.1	75	Buka	09:00–21:00	Rp 12.000–28.000	20000	\N	2026-05-03 12:45:40.561948+07	2026-05-03 12:48:08.625538+07
4	Sederhana Restaurant	4	1	3.564797	98.627026	4.5	210	Buka	08:00–22:00	Rp 20.000–50.000	35000	\N	2026-05-03 12:45:40.561948+07	2026-05-03 12:48:08.625538+07
5	Rumah Makan Garuda	4	1	3.565906	98.626422	4.3	155	Buka	08:00–22:00	Rp 18.000–45.000	31500	\N	2026-05-03 12:45:40.561948+07	2026-05-03 12:48:08.625538+07
6	Moon Chicken Hangry	3	2	3.571141	98.638354	4.2	180	Buka	10:00–23:00	Rp 25.000–60.000	42500	\N	2026-05-03 12:45:40.561948+07	2026-05-03 12:48:08.625538+07
7	KFC Ring Road	4	2	3.565318	98.625807	4.1	320	Buka	09:00–23:00	Rp 30.000–80.000	55000	\N	2026-05-03 12:45:40.561948+07	2026-05-03 12:48:08.625538+07
8	Burger King Ring Road	4	2	3.565186	98.625908	4.0	275	Buka	09:00–23:00	Rp 35.000–90.000	62500	\N	2026-05-03 12:45:40.561948+07	2026-05-03 12:48:08.625538+07
9	A&W Dr. Mansyur	1	2	3.567316	98.660835	4.3	240	Buka	09:00–22:00	Rp 28.000–75.000	51500	\N	2026-05-03 12:45:40.561948+07	2026-05-03 12:48:08.625538+07
10	Mie Gacoan	1	2	3.567404	98.645974	4.5	410	Buka	10:00–23:00	Rp 15.000–40.000	27500	\N	2026-05-03 12:45:40.561948+07	2026-05-03 12:48:08.625538+07
11	Saung Kabayan Seafood	3	3	3.561383	98.637930	4.4	165	Buka	11:00–22:00	Rp 35.000–120.000	77500	\N	2026-05-03 12:45:40.561948+07	2026-05-03 12:48:08.625538+07
12	Basnul Cafe	3	3	3.554143	98.626736	4.3	130	Buka	10:00–22:00	Rp 20.000–60.000	40000	\N	2026-05-03 12:45:40.561948+07	2026-05-03 12:48:08.625538+07
13	Hasnah Kuliner	1	3	3.571830	98.647619	4.2	95	Buka	08:00–21:00	Rp 15.000–35.000	25000	\N	2026-05-03 12:45:40.561948+07	2026-05-03 12:48:08.625538+07
14	RM Khas Batak Toba Nauli	2	3	3.555144	98.639940	4.5	190	Buka	09:00–21:00	Rp 20.000–55.000	37500	\N	2026-05-03 12:45:40.561948+07	2026-05-03 12:48:08.625538+07
15	Mie Pangsit Athing	5	3	3.540931	98.650418	4.4	220	Buka	09:00–21:00	Rp 18.000–40.000	29000	\N	2026-05-03 12:45:40.561948+07	2026-05-03 12:48:08.625538+07
16	Oui Dining	3	4	3.576313	98.648555	4.6	305	Buka	11:00–22:00	Rp 80.000–250.000	165000	\N	2026-05-03 12:45:40.561948+07	2026-05-03 12:48:08.625538+07
17	Tenank Ngumban	5	4	3.539008	98.633342	4.3	145	Buka	10:00–22:00	Rp 40.000–120.000	80000	\N	2026-05-03 12:45:40.561948+07	2026-05-03 12:48:08.625538+07
18	Sambel Lesung	4	4	3.563558	98.626200	4.4	195	Buka	10:00–22:00	Rp 45.000–130.000	87500	\N	2026-05-03 12:45:40.561948+07	2026-05-03 12:48:08.625538+07
19	Kampung Kecil	5	4	3.543566	98.645786	4.5	260	Buka	10:00–23:00	Rp 50.000–150.000	100000	\N	2026-05-03 12:45:40.561948+07	2026-05-03 12:48:08.625538+07
20	Asoka Corner	4	4	3.563051	98.626494	4.3	170	Buka	10:00–22:00	Rp 45.000–140.000	92500	\N	2026-05-03 12:45:40.561948+07	2026-05-03 12:48:08.625538+07
21	Senandika Coffee Medan	1	5	3.574847	98.647591	4.6	350	Buka	09:00–23:00	Rp 20.000–55.000	37500	\N	2026-05-03 12:45:40.561948+07	2026-05-03 12:48:08.625538+07
22	KAVE	1	5	3.566352	98.646852	4.4	210	Buka	09:00–23:00	Rp 20.000–50.000	35000	\N	2026-05-03 12:45:40.561948+07	2026-05-03 12:48:08.625538+07
23	Seis Cafe & Public Space	1	5	3.573331	98.645849	4.5	280	Buka	08:00–23:00	Rp 18.000–55.000	36500	\N	2026-05-03 12:45:40.561948+07	2026-05-03 12:48:08.625538+07
24	Champion Cafe	4	5	3.567772	98.646520	4.3	190	Buka	09:00–23:00	Rp 20.000–55.000	37500	\N	2026-05-03 12:45:40.561948+07	2026-05-03 12:48:08.625538+07
25	Ompu Gende Coffee	3	5	3.555393	98.634119	4.4	230	Buka	08:00–23:00	Rp 20.000–60.000	40000	\N	2026-05-03 12:45:40.561948+07	2026-05-03 12:48:08.625538+07
1	Rumah Makan Raihan	1	1	3.567215	98.655169	4.4	13	Buka	08:30–21:00	Rp 15.000–25.000	25000	0812-9492-3434	2026-05-03 12:45:40.561948+07	2026-05-05 20:25:42.19845+07
2	Rumah Makan Srikandi	1	1	3.573126	98.652300	4.6	291	Buka	10:00–22:00	Rp 15.000–30.000	22500	\N	2026-05-03 12:45:40.561948+07	2026-05-05 20:29:29.806321+07
\.


--
-- TOC entry 5069 (class 0 OID 33511)
-- Dependencies: 225
-- Data for Name: kedai_foto; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.kedai_foto (id, kedai_id, url, urutan) FROM stdin;
2	1	https://lh3.googleusercontent.com/proxy/2Zy4hCkWP7RTnxIFblL7VivWZTkRk4E6NdhcaWkr6CDEP8WdZ9m7Jr3jM_myjwkwdDKriMag1XKxg4mS6ZiNz7MRcscuZR1JxlIHyRJKFNUGRf-R9XL4FhB7AvvOxW_j7VFhfdPVe0U5_pNFV8f6-KsETWSogu_S2MAtTA=s1360-w1360-h1020-rw	2
7	3	https://lh3.googleusercontent.com/proxy/Fc4MszGEcPejXDG8y0zNx8abAsG5qYMsvoVxPFahMc1wpDxz1vM66uMU8-0h_NktYymLG8x-sFaV4DCB5g9Xf-1McyilCt-IL8M0SxNMhYxzqhC4QDIcj936Ou33eaxAWP8AARAhdyAIkOf_etweNezz5FzXGvKN53j_9A=s1360-w1360-h1020-rw	1
8	3	https://lh3.googleusercontent.com/proxy/Ho5aIUObUbW-mm0SeWt2NRy4vQLEv31_H6EhTcKJ6TUZdbNGmGIx5wFnazRQWu72GVYqjzw9X491VpXmQQ0hY8diulBVbjS5BasdNBR8naIvJ3xJzTiOzcnb-Oi7OZMCEUoyZJV4iYKGe3qqVNpFkWl5K_ddME1jTPuD8Q=s1360-w1360-h1020-rw	2
18	6	https://lh3.googleusercontent.com/p/AF1QipN_rDgExpauCljWDZJp7nNau-cOfwFUbtpVNhB0=s1360-w1360-h1020-rw	3
31	11	https://lh3.googleusercontent.com/p/AF1QipM_yDyirvTXI5LE230xga040ojtgEQNMsbWiaaV=s1360-w1360-h1020-rw	1
33	11	https://lh3.googleusercontent.com/p/AF1QipN0v4xWCJdVFvaDo2Ph8HVUz8dnh-SdoszNCPop=s1360-w1360-h1020-rw	3
3	1	https://lh3.googleusercontent.com/gps-cs-s/APNQkAGkN0pd7BQ1kb6Fe8c0qEnf6ZXh4OQSH95KGbPBNcSueXFsBwep6ZtJo1vbaGUycOXdQkwdkG6tkzVXbYMW-2fQWCz5zV8tQApxJtDcrcYXO-1fg1imXxH1tdwp8n2R1SAn0Q2iCw=s1360-w1360-h1020-rw	3
4	2	https://lh3.googleusercontent.com/gps-cs-s/APNQkAHs6YJ_rw03uisRoT2UkY8J2FzHcIFpmrPzk3mgSxFIb5PRp__BMvoKT5A88dsZh96ySw2cIL2wUXXXOhgdhcmS1jxVppAscc262MsrHzJq_D2Wfvl9uh-pafAc_WbJRRcU6txFgg=s1360-w1360-h1020-rw	1
9	3	https://lh3.googleusercontent.com/gps-cs-s/APNQkAEPWZWlJoxCcWfk4wtrn2J68M4GpL-LmcTyPn3xVQ287V2OmBYFnaV7K8t0r0m1id31KDJdHlgJzkfB0pTVs9-4EoM1f8RDF1T6YwLPYP4AyQfx1UEL4k6nkHkWXE-nzZOxTzzv=s1360-w1360-h1020-rw	3
10	4	https://lh3.googleusercontent.com/gps-cs-s/APNQkAE40Zj0NE00T58ydImTXdVjjYceryQ-WCGBXqII0c9kmSvGQjEOBW_1HH42d3wW3xN8Q85dZA2F39pWetAQn_PLxZTccVo4ipz23sVlQsBPCATguuCj1ljVWwEkg7_S1iMgFzrq=s1360-w1360-h1020-rw	1
11	4	https://lh3.googleusercontent.com/gps-cs-s/APNQkAHbIANO2nPquJl-qFi6531SnFMi8a2M57fv_O0kXLypEEouHi6qBDn6DXsQcofe1XpAyS6R_yNTOwOqHnVtEPb2FDKcYVWbs2ROgmK1DR3P7wTZXDmHGnlluZJ9I3H__JDu2hyi=s1360-w1360-h1020-rw	2
12	4	https://lh3.googleusercontent.com/gps-cs-s/APNQkAEuKbNBdo57rejp4kEr00v7bsN250QExpswWPHYiUZ7yeCROxSixk04m6AhdRh_eghhLwgwN7r4IANcgN-h7H0ul_5eb6ue74c3ddnr5vL3kUvR6Li4q_QtjugelcGPLx7JOMyOAQ=s1360-w1360-h1020-rw	3
13	5	https://lh3.googleusercontent.com/gps-cs-s/APNQkAGm_G9KejIaGvvwlPoJrxtKEB2grEQQF75UJO90Vn0CbjDwkr9AGc4-Ai2oAuVEGISYiZzcum4Cv9PL_kO9q08wkYOHuDs107Y3R4j2oMDP_3KVa_fuzNW3JH9l2fKLr4iyGBQyN-p1d4zC=s1360-w1360-h1020-rw	1
14	5	https://lh3.googleusercontent.com/gps-cs-s/APNQkAFjhPLGtiXiWe2KTELIAiX2hwfmhkklpvHpLWSTOX9HguZIcWAoHTlA1hx-nkBcG8kx6iQf-n5O9AUqXvYSxWUbFpu4cTq_ALpBq9ePB2KQDGqRCZ-bc7clX5AF8Cwtc7VUWeSptQ=s1360-w1360-h1020-rw	2
16	6	https://lh3.googleusercontent.com/gps-cs-s/APNQkAHmbvIqRFj2SMdRZ3WxFX33GIMFlbe05bInpFZb-aQzHaiGAKSHuJkFo2_3lfRgKnTZc0o1skNknLi3RbzIgxZCQs-xoR4eQJXlkRpGsA_K41znBGb2rn31AWOXvX7w1TsQvAuzB8EE0sXt=s1360-w1360-h1020-rw	1
17	6	https://lh3.googleusercontent.com/gps-cs-s/APNQkAEx3ZL0sTshsTGZkeaqIPQxhyHY-Lz_Lt_D-T1i2EiNahW5ynGBfNNQJLn9DMp2tJ9mJWSepxibnBXHXY0xHz9BLADjVojzByIzGl5aObUAX3oHiLLeqGPItvErwIh1d9ApR4EO0g=s1360-w1360-h1020-rw	2
19	7	https://lh3.googleusercontent.com/gps-cs-s/APNQkAFPDh4jdLUAsWORjkxgnR_Fu1SiNYgkSraRt9F-OukuEnHCGeMOhxPqAMn-NVA185dCdb3Zp9ZPW2Xh2hc2rE0Pve0gtx_2xyYaiZ-UmsZ2KAcdYAi7zgbtsh2taWRZGQLVPdxmoA=s1360-w1360-h1020-rw	1
20	7	https://lh3.googleusercontent.com/gps-cs-s/APNQkAFH1V8heqkZ6PUGjMMmsjNkb0IDz95tcb8lWrERdv3MN6gcg_lv5z07P3sDskyyCqDB73M25sNtWyrlH0Poz0fdBpql8KaUwHOEmI1tE5bp6BPAfNqsa9dEAAEXAe-CQS7FKIL4=s1360-w1360-h1020-rw	2
21	7	https://lh3.googleusercontent.com/gps-cs-s/APNQkAHZ6TAoY6ClLMkZ8hIqR36fKGkjonnuhh-GvN_n4JyIW9233ANTioW34P8J20tFt9Abn5iRJ3Qy4prnwSG1rpuvF0LK8mJcaff2F-Zsz5wH6IGa1egN-Z_sBPYR3D_2_NJeKTli_J_MsrM=s1360-w1360-h1020-rw	3
22	8	https://lh3.googleusercontent.com/gps-cs-s/APNQkAGKVUjFHedtchbYAOn9TGdIE_kNbm7w2kgfJSmMEeY7qrQ6eP_Im7wNWk9gYoaHeaPtPSSSwqxOvKLzZ1MkaonkAg81KeYL3AfVbtcX6p5cwVGljR9g0uwFad4StzZPvxvVjwerGoT90tgZ=s1360-w1360-h1020-rw	1
23	8	https://lh3.googleusercontent.com/gps-cs-s/APNQkAHCIJepg_y7MHprSOg-GIT3GHwr2l96E9IIOql-Kr2yG8ZMf0TyYMqfUVDwg3VP0lE9aFgoyBRr_fAbfp-p4DJvxo8dfFk-Dm1yR3L7WDTjYcE51UaORYM3QGy-ugQqJ46iS9RepTH_xzje=s1360-w1360-h1020-rw	2
24	8	https://lh3.googleusercontent.com/gps-cs-s/APNQkAGaW7o_5urdBtOHKnmB85mmy9oHuw2nPky5HfaSkAppKuHhako9I8RGOlb8wcLX5iYheDiNH3w-6hMb1E6iH7UBtPhM9Tscyea8p4RtD0aQU70xHe4HIsPixcAX33dmWe6X4UCuJpObs8s=s1360-w1360-h1020-rw	3
25	9	https://lh3.googleusercontent.com/gps-cs-s/APNQkAFdZVRzQ1ZQ-7VNQE6n1vRCj4FIa8srdGymv6V_9DG0BOJla1_MK0d0Jk2VTLenueO0q2fWh0nN08FxplY01TUqTeBbltnjll-JaNAu0ej4j5M8b42h0tKi5qCCcvutq0z57yMa=s1360-w1360-h1020-rw	1
26	9	https://lh3.googleusercontent.com/gps-cs-s/APNQkAHbNaoETpPQFwi15dfug5RN0W53wHUhy3vkxzG47V9vYo00I66GI9SB_E9TJXK-qQWjNM7B_7DTZ7JW_1ymL2JyFF9ZBUdY301jTx4g4KnceWEdJes0KePZQV0ROKwoT4DS7_-8=s1360-w1360-h1020-rw	2
27	9	https://lh3.googleusercontent.com/gps-cs-s/APNQkAEzDiH102sO-CkFodIgZXJniOacNcu9u3mh4a7ydcuvouQtg74LjGjqpy9XbiA4HDIT2ZpS-T2HPyIpT0-rlG3dbKwFWxP-Q8aA0JOEZAF4isBSg5YRLay5biBx07xMlb6_0foMuBBpMAnw=s1360-w1360-h1020-rw	3
28	10	https://lh3.googleusercontent.com/gps-cs-s/APNQkAEJUjJ6wF6Jo9ci6UIYuPYM-gBxRZoDtcT30nGkDL-5t6sEC3U0O7_sDHp98U1x2b9Rewi-j7YtdkVg7kHkFkGoEm-3WkSRrls0ER-qru-jjdBFdzrm_0tqMUI-sjXR916Dt8wVR5ZLQjyN=s1360-w1360-h1020-rw	1
29	10	https://lh3.googleusercontent.com/gps-cs-s/APNQkAHWjlba6cy6SK5UxOkYJ5-bZdlqifh5gHMDS4OrnWA4-9fIf8q4WKJWtbqVxrZEzeUgjef9GZCbVsq8SHVXh-Fll46e12oR4askoiAJKojZVqf6i3WBGo1pY6fWgnrk2cclTzNeI9WSBGq1=s1360-w1360-h1020-rw	2
30	10	https://lh3.googleusercontent.com/gps-cs-s/APNQkAHbV9qM2D3ArPjp2o5c_1TP5rtW_BE5QtQxxQADTs9fZicCz1DYGyNoUvxH96flKrB_wxAtB4Ve39aapvS2Ef_fy8fvxqMgoZOYR8Re7TJzRnH7lFvv8duM-aOptiG0jp7AefER=s1360-w1360-h1020-rw	3
32	11	https://lh3.googleusercontent.com/gps-cs-s/APNQkAHNIUkw5a2pW8kCB2xDE-aAMrb029FPPMWQXrvpB_A3JBO2PjHSFwSIYnQ1cZOJBM6_532TWHaaKM7IQEhrfH3HBouzpFNLP9K7Lma375XLYKlq8_MURsYSrOZCNwOCGq-Q5HHFkmF5wTsL=s1360-w1360-h1020-rw	2
47	16	https://lh3.googleusercontent.com/p/AF1QipPb9BWBO_uLMJjivOUGgCYNYpOXhruugZiZPXKR=s1360-w1360-h1020-rw	2
62	21	https://lh3.googleusercontent.com/p/AF1QipMVMUHptmf4S7pRhDhza2omi1O4NPcrhxhq7gGE=s1360-w1360-h1020-rw	2
43	15	https://lh3.googleusercontent.com/gps-cs-s/APNQkAGsvsKRWjpIncK6zhA4PtYFNAxZSqu0WRWtpphD6AwEZV31ARnkUamhh0jpk5uSSLd9jjhj06Qye5hRY5zAgNBzAgerUXelW9HXQHSrX_vq_IP6RqTSP6BfE8N4mTifCa3miYBaTQ=s1360-w1360-h1020-rw	1
44	15	https://lh3.googleusercontent.com/gps-cs-s/APNQkAEBQfiFXbvNr6gPMPVrQjWJyT3B_VeFETozBY65AXolvcckdoZxupAWBR0i9xmZ_QqiSrYUo92DYLjwo9z87uc_EaB5oh623brUgQKLRHr4u0rEWsAxE71cLxu4P9dexh8AdDL0=s1360-w1360-h1020-rw	2
45	15	https://lh3.googleusercontent.com/gps-cs-s/APNQkAHGQmlkdQRA1lSvDNrZ2UAS9TFZ14aImazLj-ABS_YbTJqIg1J3Flb_K-N296fUeDpooGkiGmyO4CbmCOvOkp2d7r897Ok5-ftyQyM6eJpRjkBauroMX0nhmyzIgebGcuIpGoUcLQ=s1360-w1360-h1020-rw	3
40	14	https://lh3.googleusercontent.com/gps-cs-s/APNQkAHNAG2d4hjRgROXsNqGx0ishTCsjfIBS6Otuuk_VtNbJcK74swtnSHEHr7epDH2k96uEuyD9LMQ7tGptTsBR7Nj_U6i2LdS-Kt2wDGjEYQa23AbqArl9dMcKDL96fXN0dW0JUd7=s1360-w1360-h1020-rw	1
41	14	https://lh3.googleusercontent.com/gps-cs-s/APNQkAEV45APsWi77Q79xgkS9-8WSCFPocQ4T4yT_gqFngJS8uF147EFZfYbMw5nak7Qunt0uYdXyfEu0MUvxYioYj-oUqnkd64FN09htCcAdXN5qlIgfHvCBaeEo5sVNXCvr5MU2y-SYw=s1360-w1360-h1020-rw	2
42	14	https://lh3.googleusercontent.com/gps-cs-s/APNQkAHBXiqtwkyGAVoSUHZRgH-DJh7fW8j8PCYKE7Q4l_zZBqlP27Krr_3oAi4ugOY715fN7CDFfIC4d2SI8Dl5Wxmo4PwwbvnXtOMKYkla8ndCuj-0Wx1ZV7UQSAZ0RbUxURGUBCpe_Q=s1360-w1360-h1020-rw	3
37	13	https://lh3.googleusercontent.com/gps-cs-s/APNQkAHv453uDW4lf9UIDIhu502D2iJ_VGV9R3xuesHUURDQ3kOWwyU_feGjckS_53ET9-K6E_or-2gm4InKO_to9-wsF1nXvsv7-s-fp5mU7y0J_4b1nEwXqMvV-3zLAkeGe5O5GXda=s1360-w1360-h1020-rw	1
38	13	https://lh3.googleusercontent.com/gps-cs-s/APNQkAES3s_Eu01EqjnqfrddcJTFfYv4ZqxPR0l9KU-Y868YxwWekPs3gdA_TH_DTh0wH9sGAc8kdfD4MChhTF4_LmpXtvcXDq2nEwTz8hgmlG8OR4C0j-S9QramXd-HuMMVQfRy2Ujtaw=s1360-w1360-h1020-rw	2
39	13	https://lh3.googleusercontent.com/gps-cs-s/APNQkAH3Y_HgKIiqvvnz-xZIGVS1CftP6MnBRKMfhhzjd8O2VAxu2ftI3-7C79e-CTWdGe_jiC5pN86LWAkW8KLM3weNcPGU27JtmCwsaAjs5Zzo3VlpbAi2L8tUlu5_n7smwKPM7ql1BTbZn3ZV=s1360-w1360-h1020-rw	3
55	19	https://lh3.googleusercontent.com/grass-cs/ANxoTn3Mmi8emdqQnLfzDG7bbhYI3tYd9FbCOIV83YlJYaBQyDSXJv_iIO4NErjGUwXz6tyaZiEoAoF5ktwc2Et7hqjDy9A6-AaVI0d_NXu4drznTij3Z7oSZiN__IKiM-hE_y7EI3sG=s1360-w1360-h1020-rw	1
56	19	https://lh3.googleusercontent.com/gps-cs-s/APNQkAFzpLIHXE3pFWNXMg8j3hy7jLg__HLrDCa6nKK8iFqeV9b8kQ3eoFP_3UhS0rdavBNCkoDFM1C_mpI4cy16tBho-vDy2guCeLKhv_3MTelwbcqa-xHGG-l1QdGvmpO5_rqum6_Oz2mBJaN2=s1360-w1360-h1020-rw	2
57	19	https://lh3.googleusercontent.com/gps-cs-s/APNQkAF5g4XTWWCyvTzPRchmVIvgbcKuhy0V1FeR3JoHEvnsKCYZKIqXWjc-JZLn4PsuRV94WJ1UdJyGPN6-zGJJ0YtZiyfbmaPbBv2k9LwkkUrV_v-yCP49iOxMaHgskYlr4wgvpWVmkw=s1360-w1360-h1020-rw	3
52	18	https://lh3.googleusercontent.com/gps-cs-s/APNQkAGdi4dHmDYikIk7iLFsm7Ph1SrB_nQ1kQ6RhJddGCsKBn36ZOqrqk9OD5X7XhZTW1ysEYZkH0t1atPLyn3e-aKRAibN4m5u37ypDa-qTYikHDpA4I9Hy7g0szlLsDQYhGwoPWHHUA=s1360-w1360-h1020-rw	1
53	18	https://lh3.googleusercontent.com/gps-cs-s/APNQkAG0_zmKvt7UAm09f2UsjN9EwPn1DK5TKnWya6rP89TTdZ72Vs173x0vTHSXtVyilaNvP383RVGvTFbhRv1_zieWPmdcjB3I1O4BTdpnab5QgeD6piQBqTnEYKjQpiZxnRWwudxBMQ=s1360-w1360-h1020-rw	2
54	18	https://lh3.googleusercontent.com/gps-cs-s/APNQkAHXfbz2Rw06Dg-MyjZ4BLBknNXYukZYlCtsnkPTK_8zHPT4lzTkr9ECB8b2hMmFyaveoyEK9_faf896oqRpkfT7vNnO7JZfY2JP2nosrw1rypfrkvkbNaY6898xIB1X2c9NEhqIkA=s1360-w1360-h1020-rw	3
49	17	https://lh3.googleusercontent.com/gps-cs-s/APNQkAF7kOcqlRAaM3CyMwAxaZxHWCkG2HINxqve6F8osG1K2K1JZIQbo5lenMzwjCsr4A7SqOjKfnxVW6H-qvir72k_Q3Hh26h_gw457eYfAQgU3JjJCF3Axr1hi2erpkPZPnSVlxZc2tcqMXbi=s1360-w1360-h1020-rw	1
50	17	https://lh3.googleusercontent.com/gps-cs-s/APNQkAHwdAtX6fC7dcVT3rjzuccziKbZNh4ds03SuARiwdIhJPNqNCFXTPVsJq00IcAnVV1_Ne3eLxx6672jt2e1H82vVWOXdmOGIWhdiDnoyvOjTD6xgaqC1q7Z6zCpH4C6i8I-EqE0xu0iPjQ=s1360-w1360-h1020-rw	2
51	17	https://lh3.googleusercontent.com/gps-cs-s/APNQkAF-3HS1NXOKPu4QoF_iem2o2FEhxCA48pIYVhWZLARrXlIH-UBnX2WETvr1Vda0uU_AE94waW8i57fKEVskaYyDpmiFxP2jhm1rD8YO4N8hDn1e7JisNvn7FV3HxAsrubXBX2uCQp6HEjKL=s1360-w1360-h1020-rw	3
46	16	https://lh3.googleusercontent.com/gps-cs-s/APNQkAGo1RBFe5qd5f6f24LBV1X5MekmNmSPXt6fh4V-uUbR7QMJSsp7qNa9X7AZfd5lXij6mMMzmP4E1OzhOy6425KiJmCEhXwfZJV-aHY9sJxLj8Eken2FhrOvXphiN-_ekkIkkHkkqg=s1360-w1360-h1020-rw	1
48	16	https://lh3.googleusercontent.com/gps-cs-s/APNQkAEiZ6nmOrl4S3eRXVPozRDQIv47ir1aqc9YDICCoxJbvf8mXmfI9WcA8inCPdS4nijB23jxnyIYAfr1RYH3oCVrLiJ8jHCq-d_zyGtPcAQQ5OuYvhlpHKyqag9hX1RC2tf0At5emg=s1360-w1360-h1020-rw	3
58	20	https://lh3.googleusercontent.com/gps-cs-s/APNQkAGiPzZ4gJNm8UiqZypHXK3ytHxQ8lArnoRBGILPw4ikNWhjY2tR5m74TKLDyOzekwVcYohZIH9v6PBDp49Gm8jx59FC0cB3CCNo2vIiezll5R-50XUGXI7GNBiRiR12HnfI4Ke4=s1360-w1360-h1020-rw	1
59	20	https://lh3.googleusercontent.com/gps-cs-s/APNQkAGteZy7fubYq6y-QiapTTuPPWvogHMtj4Rsx8uFiwtY4HQOWcHmsocX-nG9BxUNBzr1j3Hvf2-JeO9SNnubYwzcSgGoiQhxZUIHrgaEQR8pvzQaRGik44MUrpcPu2VO6xcvyqvKFg=s1360-w1360-h1020-rw	2
60	20	https://lh3.googleusercontent.com/gps-cs-s/APNQkAH3Dm0Y8LqTrBFKKNvaivWWfpko3FlULrErycn8okiGKmePart62zA9mAj92b_SrA-X0E2vAp7YK1nZoIgNCQy5g0HblxRBtzkzQg1f3L9qNyHrERVpOjS3KdAuVzVFw2O7LLM=s1360-w1360-h1020-rw	3
61	21	https://lh3.googleusercontent.com/gps-cs-s/APNQkAFK443vfw64kYasz3KjIUH2Z9zGxbotoTergpNVIP6-mtBXzJNrturd9RulhnzcFA6P4JRTIXOb7SELICc70XRBrdR8cr6M_INSf9tOyJ30IyIVMpu8YTEoiAxBsgZvdP7pwyo=s1360-w1360-h1020-rw	1
63	21	https://lh3.googleusercontent.com/gps-cs-s/APNQkAGl82zVEkkZXdjKrEUPo0hB0o2NQLwuErhLJEcc1h20d9AP4CTE1LG-HHp-4bZBuCKnSxtj8K2FBEX6HB77279abtp0DZ7-Y4GusknVq9dOE092mNun11mUoXjguhUnfJxtHNw=s1360-w1360-h1020-rw	3
64	22	https://lh3.googleusercontent.com/gps-cs-s/APNQkAG-Gor_QHPdrJZjJwE6baJn4LnLdt6Z_jw3pMTiIp_a8VQT_iAcbDg0zaAQzc5Vdb7HSiEl0DuVB7JB5x-rfWzZy1cYYzqAUpinBU3ZUMp0CY4u2wXH8vaJqC6PCamOojuDgd8t=s1360-w1360-h1020-rw	1
65	22	https://lh3.googleusercontent.com/gps-cs-s/APNQkAFQp0utUZhrmnAHUPlljTDLMlDrBeWDuMRXg1VXHTJ4BR-dfFmJxsw1P9qWTjaWQQgkJJ3AAiA_0BNObW76K31-86CIIYUl3Mp40pPVIVPPvtU-O2fClDZXmpbEPrhwPvFJwlVMOthuivei=s1360-w1360-h1020-rw	2
1	1	https://lh3.googleusercontent.com/gps-cs-s/APNQkAG4IzqTObmg8Soje9DqSwi8JSYYTyO4ffgfB9Vw20GJL_rEjPsH3H3RXOJTmdMTHWpdINb1Em3JCElieMlQ_elmQbalU15ozr4Y3irOK5TB90kVMyEERWC4eV9gJC0LjDNVyTvfWQ=s1360-w1360-h1020-rw	1
5	2	https://lh3.googleusercontent.com/grass-cs/ANxoTn1QSsjqNl4xZc8BDwa3cjsNvKqKlxmHVWMluI29Znc9B_8meR6WG3HbB0fregnbT19unGrt0wcQQkW49y-e12eX6CYTbLKwXbP6ejc5R-MedpAzJvyT0US5gGz3mvKLSaVBpYtagg=s1360-w1360-h1020-rw	2
6	2	https://lh3.googleusercontent.com/gps-cs-s/APNQkAGgMnjb-2FxflIF50MgVtPXxExZHY6qvT2Efb77pqnGd8LlScCquc93PihZIWCTbuhUAzyiCs84MSe35NAMpNmVyG7GvsVYRZ4Jy7aYFHowuq1dFRImq95g9KI-OXZWMQOOFhkS3g=s1360-w1360-h1020-rw	3
15	5	https://lh3.googleusercontent.com/gps-cs-s/APNQkAH84uX-pdHFbZv3FXrGUoR4oFiCKIXIagZSi19eLBYlteIRTiiYhFYZ61-97s3YHNKQ7dUtnfhnb_928ieZj6XY_0q48J6EqdAUy5al6SiCP--udagDFHM1QwdsKjrIaq46FerzrA=s1360-w1360-h1020-rw	3
34	12	https://lh3.googleusercontent.com/gps-cs-s/APNQkAFB-JrSSngD07AmlLf-fX7WVL8i2yh6Nqgzp2hG_nI3DhuZktpcWUc7nOZ3QOe4JdGfBefHDb0o_SrkmhOaxxxuBH0YYoslV5qR0aUfBTm6mAMEPXmB9qOaFfbKfkM7igmLwuEkbg=s1360-w1360-h1020-rw	1
35	12	https://lh3.googleusercontent.com/gps-cs-s/APNQkAGGdcnPCn4ez8_aVi6kAxuPGQX1HjZCmW_Vw2m3qFeeLBeCe3EgAXVMOYZhlmUulDQP7y9l75p85HxPEhIxk-eLm-FdGgZKrxrICRxgA5X31mhEku_pHBUyPfMN0vofGUZ13Ivf=s1360-w1360-h1020-rw	2
36	12	https://lh3.googleusercontent.com/gps-cs-s/APNQkAFPWZ11dEA85vj4_LDodp9yBNqcExPQVZvZy-fSvle4VpxSgUrz-5PqBlxQFqRHZm_7V3vSvVvFiCFR7saM4-tbBp30OWZRCYEHXK7ix18KQwUTErnAlgSID8-HI6MNk5LnF9U6N2DMkRfP=s1360-w1360-h1020-rw	3
67	23	https://lh3.googleusercontent.com/gps-cs-s/APNQkAGMSKHSOiiWipN7KDo1-uBoo-dA6VBdyyR6nfc1GLJCegEDNanpEbGSwC3_q8mzgFODyXLSZ3y5zBamR8EHNj7V1tPD-_eSlDBT1-X7Sa1OGl5LnB1TUasQfTb1Ree9QSE2n7WI9g=s1360-w1360-h1020-rw	1
68	23	https://lh3.googleusercontent.com/gps-cs-s/APNQkAFSPQUoSIYgOYNx5lQGT8b4SrXiBqtXZFjcuYkt3rvmZFHwKdRLntR7Fc1JhffW38LodBHWfa_LFP6KtWe3lrue2_QZXiJRp5ho-gIL_d_Y_TO1DpPCp363LhbiqydyDN4itBsIJsK5EGN0=s1360-w1360-h1020-rw	2
69	23	https://lh3.googleusercontent.com/gps-cs-s/APNQkAE9IZy7rEFETpKSSGJtMhvS_8KVM4HVIS3Vaid3q83oJiKYU-cMfZiMx56GYlOnqi8DYKimi7o0azc3qpvkhGq-cqaFuL7DGRev_ppMttjW8pheKImXnKt-HfowhXxpqL1XSBsb=s1360-w1360-h1020-rw	3
73	25	https://lh3.googleusercontent.com/gps-cs-s/APNQkAH7s-9BUPKiFhzCRS6CfaIsPDDPts81EobsB-qUScGdTMV1xBjfz09Knq2gP0qu50KNOYK_GC-ytjeZuDfTUz25ZwTbRLBFL7vVG14PyIGq521UWjZcUVUj_orenoB0co2qGKE=s1360-w1360-h1020-rw	1
74	25	https://lh3.googleusercontent.com/gps-cs-s/APNQkAGBGaxguf8Nkxbr8O4L6tgBfBeQ8YV_e1eKG2QDhylo7XfX-1j6d5skWr3WZssBvjTczKFbIwvyzpeUqgiHB4pVIqJCIF8UQ7SHoGl2jg62DrCQkHMurDhP8SDdDTWtp-PDV9pArA=s1360-w1360-h1020-rw	2
75	25	https://lh3.googleusercontent.com/gps-cs-s/APNQkAEu31dH8qzmkJtk1t4zWsY88IkaLHOa7_cBT9Co5GSFVG2QU7sDnPam0WFDqyhRQZi8kQu9JdWqc-7fbbXuNJeThwNcH5FqgUKwjYKiYmcLxqPxqUWW1lpyd4PDY6gXvDK_iJp7=s1360-w1360-h1020-rw	3
66	22	https://lh3.googleusercontent.com/gps-cs-s/APNQkAHmPvh27lN4ok9eVSAFArO_2e_ZYuEs8t55O8bu7lG_0tWZStvyXJzdMJvVaDCBq3T6vB65x-Wm-2ADHZXkRQW0TfpIkmZ3s6nbieN549fYElMpZbmM5dhMUA6wBHTnvcunzpSd6JYtsWTm=s1360-w1360-h1020-rw	3
70	24	https://lh3.googleusercontent.com/gps-cs-s/APNQkAG1BSBd790G6GbeDKtxOLZizMZ9dv39yIkuZfs3TMqHaK_fnxRnJgpUa8oLUoTJce9T7hf8Sv9Mj1po4CCvHJyuxv7IReTPyfa98ddnZMNYT0sjyi5htOlSqjdSkWGrUV3ni2BNzJoXwQLE=s1360-w1360-h1020-rw	1
71	24	https://lh3.googleusercontent.com/gps-cs-s/APNQkAHVk4ovR3Q2_d6sQRhPWP7xoy6uELWKoFHA5BsKNVnmVHtlThs4EV9sZEWlm5oAtRSJIcisg9UvEoweHvYSCuouH5QZrOnIgpEwAvsc3HukH0Y_gxcdTf4RNJwTynuZG8CdeGKcXQ=s1360-w1360-h1020-rw	2
72	24	https://lh3.googleusercontent.com/gps-cs-s/APNQkAFWanztTBRy6ZSgzw96xMC8uUfhVEXDq1zETADwLBk6Vyh7uxCRdnhaNaWJP1ZlrUjxTEV5iXd4XKOraE5S1aM1eH9AzLvUtxGHrfQ5R22h4wZhKMSsQSrhX60JwwxeUYgKxoG-UQ=s1360-w1360-h1020-rw	3
\.


--
-- TOC entry 5064 (class 0 OID 33450)
-- Dependencies: 220
-- Data for Name: kelurahan; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.kelurahan (id, nama) FROM stdin;
1	PB Selayang I
2	PB Selayang II
3	Tanjung Sari
4	Asam Kumbang
5	Sempakata
\.


--
-- TOC entry 5078 (class 0 OID 0)
-- Dependencies: 221
-- Name: kategori_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.kategori_id_seq', 5, true);


--
-- TOC entry 5079 (class 0 OID 0)
-- Dependencies: 224
-- Name: kedai_foto_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.kedai_foto_id_seq', 75, true);


--
-- TOC entry 5080 (class 0 OID 0)
-- Dependencies: 219
-- Name: kelurahan_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.kelurahan_id_seq', 5, true);


--
-- TOC entry 4898 (class 2606 OID 33474)
-- Name: kategori kategori_nama_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kategori
    ADD CONSTRAINT kategori_nama_key UNIQUE (nama);


--
-- TOC entry 4900 (class 2606 OID 33472)
-- Name: kategori kategori_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kategori
    ADD CONSTRAINT kategori_pkey PRIMARY KEY (id);


--
-- TOC entry 4909 (class 2606 OID 33523)
-- Name: kedai_foto kedai_foto_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kedai_foto
    ADD CONSTRAINT kedai_foto_pkey PRIMARY KEY (id);


--
-- TOC entry 4906 (class 2606 OID 33499)
-- Name: kedai kedai_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kedai
    ADD CONSTRAINT kedai_pkey PRIMARY KEY (id);


--
-- TOC entry 4894 (class 2606 OID 33459)
-- Name: kelurahan kelurahan_nama_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kelurahan
    ADD CONSTRAINT kelurahan_nama_key UNIQUE (nama);


--
-- TOC entry 4896 (class 2606 OID 33457)
-- Name: kelurahan kelurahan_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kelurahan
    ADD CONSTRAINT kelurahan_pkey PRIMARY KEY (id);


--
-- TOC entry 4907 (class 1259 OID 33533)
-- Name: idx_foto_kedai; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_foto_kedai ON public.kedai_foto USING btree (kedai_id, urutan);


--
-- TOC entry 4901 (class 1259 OID 33530)
-- Name: idx_kedai_kategori; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_kedai_kategori ON public.kedai USING btree (kategori_id);


--
-- TOC entry 4902 (class 1259 OID 33529)
-- Name: idx_kedai_kelurahan; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_kedai_kelurahan ON public.kedai USING btree (kelurahan_id);


--
-- TOC entry 4903 (class 1259 OID 33532)
-- Name: idx_kedai_rating; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_kedai_rating ON public.kedai USING btree (rating DESC);


--
-- TOC entry 4904 (class 1259 OID 33531)
-- Name: idx_kedai_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_kedai_status ON public.kedai USING btree (status);


--
-- TOC entry 5061 (class 2618 OID 33538)
-- Name: v_kedai_lengkap _RETURN; Type: RULE; Schema: public; Owner: postgres
--

CREATE OR REPLACE VIEW public.v_kedai_lengkap AS
 SELECT k.id,
    k.nama,
    kel.nama AS kelurahan,
    kat.nama AS kategori,
    kat.color AS kategori_color,
    kat.emoji AS kategori_emoji,
    (k.lat)::double precision AS lat,
    (k.lng)::double precision AS lng,
    (k.rating)::double precision AS rating,
    k.reviews,
    k.status,
    k.jam,
    k.harga,
    k.harga_rata,
    k.telp,
    array_agg(DISTINCT f.url ORDER BY f.url) AS foto_urls
   FROM (((public.kedai k
     JOIN public.kelurahan kel ON ((kel.id = k.kelurahan_id)))
     JOIN public.kategori kat ON ((kat.id = k.kategori_id)))
     LEFT JOIN public.kedai_foto f ON ((f.kedai_id = k.id)))
  GROUP BY k.id, kel.nama, kat.nama, kat.color, kat.emoji
  ORDER BY k.id;


--
-- TOC entry 4913 (class 2620 OID 33534)
-- Name: kedai set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.kedai FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- TOC entry 4912 (class 2606 OID 33524)
-- Name: kedai_foto kedai_foto_kedai_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kedai_foto
    ADD CONSTRAINT kedai_foto_kedai_id_fkey FOREIGN KEY (kedai_id) REFERENCES public.kedai(id) ON DELETE CASCADE;


--
-- TOC entry 4910 (class 2606 OID 33505)
-- Name: kedai kedai_kategori_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kedai
    ADD CONSTRAINT kedai_kategori_id_fkey FOREIGN KEY (kategori_id) REFERENCES public.kategori(id);


--
-- TOC entry 4911 (class 2606 OID 33500)
-- Name: kedai kedai_kelurahan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kedai
    ADD CONSTRAINT kedai_kelurahan_id_fkey FOREIGN KEY (kelurahan_id) REFERENCES public.kelurahan(id);


-- Completed on 2026-05-30 18:59:37

--
-- PostgreSQL database dump complete
--

\unrestrict wZ9r7OtYfbQaXmghodZKtebJJIktpZwe3OqFBmQoXas0oPzVWyiHGHCE618LTf5

