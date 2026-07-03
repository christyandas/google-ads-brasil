# Configurar o gmc-mcp (Google Merchant Center)

Cada usuário conecta com as **próprias credenciais**. O processo leva ~10 minutos.

## 1. Google Cloud Console ([console.cloud.google.com](https://console.cloud.google.com))

1. Crie um projeto (ou use um existente).
2. **APIs e serviços → Biblioteca** → busque **"Merchant API"** → **Ativar**.
   ⚠️ Não confunda com "Content API for Shopping" (deprecada).
3. **IAM e administrador → Contas de serviço → Criar conta de serviço**
   - Nome: `gmc-mcp` → Criar e continuar → pule as etapas de permissão → Concluído.
4. Clique na conta criada → aba **Chaves → Adicionar chave → Criar nova chave → JSON**.
   - Salve o arquivo em local seguro, ex.: `C:\Users\SEU_USUARIO\.claude\secrets\gmc-sa.json`
   - **Nunca** suba esse arquivo para o GitHub.

## 2. Merchant Center ([merchants.google.com](https://merchants.google.com))

1. Anote o **ID de 10 dígitos** (canto superior direito).
2. Engrenagem ⚙️ → **Acesso e serviços → Pessoas e acesso → Adicionar pessoa**
   - E-mail: `gmc-mcp@SEU-PROJETO.iam.gserviceaccount.com`
   - Funções: **Administrador** e **Desenvolvedor de API** ← as duas!
   - (Sem "Desenvolvedor de API" a Merchant API retorna erro 401.)

## 3. Registrar e testar

**Mac / Linux (Terminal):**
```bash
# registrar o servidor MCP (se não fez pelo install.sh)
claude mcp add gmc --scope user -e GMC_ACCOUNT_ID=SEU_ID_10_DIGITOS -e "GMC_SERVICE_ACCOUNT_KEY=/caminho/para/gmc-sa.json" -- gmc-mcp run

# registro único do projeto na Merchant API
export GMC_ACCOUNT_ID="SEU_ID_10_DIGITOS"
export GMC_SERVICE_ACCOUNT_KEY="/caminho/para/gmc-sa.json"
gmc-mcp register-gcp --developer-email seu@email.com

# conferir a configuração
gmc-mcp describe
```

**Windows (PowerShell):**
```powershell
claude mcp add gmc --scope user -e GMC_ACCOUNT_ID=SEU_ID_10_DIGITOS -e "GMC_SERVICE_ACCOUNT_KEY=C:\caminho\para\gmc-sa.json" -- gmc-mcp run

$env:GMC_ACCOUNT_ID = "SEU_ID_10_DIGITOS"
$env:GMC_SERVICE_ACCOUNT_KEY = "C:\caminho\para\gmc-sa.json"
gmc-mcp register-gcp --developer-email seu@email.com

gmc-mcp describe
```

O `register-gcp` envia um convite de "Desenvolvedor de API" para o e-mail
informado — aceite-o na caixa de entrada.

## 4. Verificar

Reinicie o Claude Code e pergunte: **"roda um health check no gmc"**.
Esperado: `7/7 checks ok`.

## Solução de problemas

- **401 API_DEVELOPER**: falta a função "Desenvolvedor de API" em algum usuário
  verificado do Merchant Center (passo 2).
- **403 / PERMISSION_DENIED**: a service account não foi adicionada como Admin,
  ou a Merchant API não está ativada no projeto.
- **Convite pendente**: o e-mail do register-gcp precisa ser aceito para
  algumas operações.
