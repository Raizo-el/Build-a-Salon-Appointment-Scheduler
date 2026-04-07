CREATE TABLE customers (
  customer_id SERIAL PRIMARY KEY,
  phone VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL
);

CREATE TABLE services (
  service_id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL
);

CREATE TABLE appointments (
  appointment_id SERIAL PRIMARY KEY,
  customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
  service_id INTEGER NOT NULL REFERENCES services(service_id),
  "time" VARCHAR(255) NOT NULL
);

INSERT INTO services (name) VALUES
  ('cut'),
  ('color'),
  ('perm'),
  ('style'),
  ('trim');

SELECT pg_catalog.setval('public.services_service_id_seq', (SELECT MAX(service_id) FROM public.services));
