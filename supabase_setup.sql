-- ============================================================
-- O SOM DA MAGIA — comentários com moderação
-- Cole tudo no Supabase: SQL Editor > New query > Run
-- ============================================================

-- 1) Comentários e ideias (entram como PENDENTES)
create table if not exists public.comentarios (
  id          bigint generated always as identity primary key,
  tipo        text not null default 'comentario' check (tipo in ('comentario','ideia')),
  nome        text not null default 'Visitante' check (char_length(nome) <= 40),
  texto       text not null check (char_length(texto) between 1 and 500),
  aprovado    boolean not null default false,
  created_at  timestamptz not null default now()
);

-- 2) Avaliações por estrelas (públicas, sem moderação)
create table if not exists public.avaliacoes (
  id          bigint generated always as identity primary key,
  nota        int not null check (nota between 1 and 5),
  created_at  timestamptz not null default now()
);

alter table public.comentarios enable row level security;
alter table public.avaliacoes  enable row level security;

-- Visitante (anon): pode ENVIAR, mas só como pendente
drop policy if exists "visitante envia pendente" on public.comentarios;
create policy "visitante envia pendente" on public.comentarios
  for insert to anon with check (aprovado = false);

-- Visitante (anon): só VÊ os aprovados
drop policy if exists "visitante ve aprovados" on public.comentarios;
create policy "visitante ve aprovados" on public.comentarios
  for select to anon using (aprovado = true);

-- Só VOCÊ (este e-mail, logado no admin.html): vê tudo, aprova e exclui
-- Troque o e-mail abaixo se for usar outro no login.
drop policy if exists "admin ve tudo" on public.comentarios;
create policy "admin ve tudo" on public.comentarios
  for select to authenticated using (auth.jwt()->>'email' = 'denisdgo@gmail.com');

drop policy if exists "admin aprova" on public.comentarios;
create policy "admin aprova" on public.comentarios
  for update to authenticated using (auth.jwt()->>'email' = 'denisdgo@gmail.com') with check (true);

drop policy if exists "admin exclui" on public.comentarios;
create policy "admin exclui" on public.comentarios
  for delete to authenticated using (auth.jwt()->>'email' = 'denisdgo@gmail.com');

-- Avaliações: qualquer um vota e vê a média
drop policy if exists "todos votam" on public.avaliacoes;
create policy "todos votam" on public.avaliacoes
  for insert to anon, authenticated with check (true);

drop policy if exists "todos veem votos" on public.avaliacoes;
create policy "todos veem votos" on public.avaliacoes
  for select to anon, authenticated using (true);
