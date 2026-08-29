-- GM FLEX Financeiro - Taxa de Pacotes
-- Configuração por empresa de um custo por pacote ML e SH, aplicado como
-- despesa no cálculo do Lucro Líquido (Entrada de Pacotes / Fechamento / Dashboard).
--
-- Segue o mesmo padrão usado por "settings" (uma linha por empresa, upsert por
-- company_id) e reaproveita as funções já existentes public.set_updated_at()
-- e public.current_company_id() (definidas em migrations.sql).
--
-- Diferença proposital de permissão em relação a "settings": aqui QUALQUER
-- usuário autenticado da empresa pode ativar/desativar e editar as taxas
-- (não é restrito a Administrador/Gerente como em settings_write_manager) —
-- decisão de produto explícita para esta funcionalidade. O isolamento entre
-- empresas continua garantido por current_company_id() em todas as políticas.
--
-- Idempotente: pode ser executada novamente sem apagar dados.

CREATE TABLE IF NOT EXISTS public.package_fee_settings (
  company_id UUID PRIMARY KEY REFERENCES public.companies(id) ON DELETE CASCADE,
  enabled BOOLEAN NOT NULL DEFAULT false,
  ml_rate NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (ml_rate >= 0),
  sh_rate NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (sh_rate >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS set_package_fee_settings_updated_at ON public.package_fee_settings;
CREATE TRIGGER set_package_fee_settings_updated_at
  BEFORE UPDATE ON public.package_fee_settings
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.package_fee_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS package_fee_settings_select ON public.package_fee_settings;
DROP POLICY IF EXISTS package_fee_settings_write_company_user ON public.package_fee_settings;

CREATE POLICY package_fee_settings_select ON public.package_fee_settings
  FOR SELECT USING (company_id = public.current_company_id());

CREATE POLICY package_fee_settings_write_company_user ON public.package_fee_settings
  FOR ALL USING (company_id = public.current_company_id())
  WITH CHECK (company_id = public.current_company_id());

-- Habilita Realtime (mesmo padrão usado em migrations.sql / motoboys_module.sql)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM pg_publication_tables
     WHERE pubname = 'supabase_realtime'
       AND schemaname = 'public'
       AND tablename = 'package_fee_settings'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.package_fee_settings;
  END IF;
END $$;
