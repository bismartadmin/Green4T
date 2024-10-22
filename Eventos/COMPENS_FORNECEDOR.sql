create or replace PROCEDURE COMPENS_FORNECEDOR (attr_ IN VARCHAR2) IS

prel_payment_id_ FLOAT := NULL;
p0_ VARCHAR2(32000) := NULL;
p1_ VARCHAR2(32000) := NULL;
p2_ VARCHAR2(32000) := NULL;
p3_ VARCHAR2(32000) := NULL;
p4_ VARCHAR2(32000) := NULL;
p5_ VARCHAR2(32000) := NULL;
p6_ FLOAT           := NULL;
currency_ varchar2(3200):= client_sys.Get_Item_Value('currency',attr_);
identity_  varchar2(3200):= client_sys.Get_Item_Value('identity',attr_);
company_ varchar2(3200):= client_sys.Get_Item_Value('company',attr_);
series_id_ varchar2(3200):= client_sys.Get_Item_Value('series_id',attr_);
series_no_ varchar2(3200):= client_sys.Get_Item_Value('series_no',attr_);


CURSOR c_Adiantamento IS
select OBJID, OBJVERSION, COMPANY, PARTY_TYPE, IS_AUTHORIZED, IS_PARKED_PAYMENT, ADV_INVOICE, LEDGER_ITEM_SERIES_ID, LEDGER_ITEM_ID,
SELF_BILLING_REF,  INSTALLMENT_ID, LEDGER_ITEM_VERSION, BRANCH, IDENTITY, PARTY_NAME, DUE_DATE,
INVOICE_DUE_DATE, LEDGER_STATUS_TYPE, CURRENCY, IS_INVOICE,
decode(IFSGFT.Payment_Proposal_API.Is_Invoice_Used_In_Proposals2(COMPANY, IDENTITY, PARTY_TYPE, LEDGER_ITEM_SERIES_ID, LEDGER_ITEM_ID, LEDGER_ITEM_VERSION,INSTALLMENT_ID)
     ,'TRUE','TRUE',IFSGFT.Payment_Order_API.Is_Invoice_Used_In_Orders2(COMPANY, IDENTITY, PARTY_TYPE, LEDGER_ITEM_SERIES_ID, LEDGER_ITEM_ID, LEDGER_ITEM_VERSION,INSTALLMENT_ID))PROPOSAL ,
IFSGFT.Payment_Proposal_API.Get_Proposal_List_For_Invoice (COMPANY, IDENTITY, PARTY_TYPE, LEDGER_ITEM_SERIES_ID, LEDGER_ITEM_ID, LEDGER_ITEM_VERSION,INSTALLMENT_ID) PROPOSAL_INVOICE,
IFSGFT.Payment_Order_API.Get_Order_List_For_Invoice (COMPANY, IDENTITY, PARTY_TYPE, LEDGER_ITEM_SERIES_ID, LEDGER_ITEM_ID, LEDGER_ITEM_VERSION,INSTALLMENT_ID) INVOICE,
ORDER_REFERENCE, FULL_AMOUNT VALOR, REST_AMOUNT VALOR_ABERTO
from IFSGFT.LEDGER_ITEM16
where IS_AUTHORIZED = 'TRUE'
and (PARTY_TYPE_DB='COMPANY' OR PARTY_TYPE_DB='SUPPLIER' )
and PARKED_PAY_TYPE_DB = 'SUPPLIER'
and LEDGER_ITEM_SERIES_ID = 'SUPIA'
--and LEDGER_ITEM_ID like 'ADD%'
and REST_AMOUNT < 0
and decode(IFSGFT.Payment_Proposal_API.Is_Invoice_Used_In_Proposals2(COMPANY, IDENTITY, PARTY_TYPE, LEDGER_ITEM_SERIES_ID, LEDGER_ITEM_ID, LEDGER_ITEM_VERSION,INSTALLMENT_ID)
     ,'TRUE','TRUE',IFSGFT.Payment_Order_API.Is_Invoice_Used_In_Orders2(COMPANY, IDENTITY, PARTY_TYPE, LEDGER_ITEM_SERIES_ID, LEDGER_ITEM_ID, LEDGER_ITEM_VERSION,INSTALLMENT_ID)) = 'FALSE'
and CURRENCY = currency_
and COMPANY = company_
and (IDENTITY = identity_ ) --02209569958
FETCH FIRST 1 ROW ONLY;

r_Adiantamento c_Adiantamento%ROWTYPE;


BEGIN
    OPEN c_Adiantamento;
    FETCH c_Adiantamento INTO r_Adiantamento;
    IF c_Adiantamento%NOTFOUND THEN
      transaction_sys.set_status_info('Não existe Adiantamento para o Fornecedor: ' || identity_ || '.','INFO');
      CLOSE c_Adiantamento;
    END IF;

      transaction_sys.set_status_info('Criando a Compensação .','INFO');
       prel_payment_id_ := IFSGFT.PREL_PAYMENT_API.Get_Prel_Payment_Id;
       p3_ := 'COMPANY'||chr(31)||r_Adiantamento.COMPANY||chr(30)||
              'PAY_DATE'||chr(31)||TO_CHAR(SYSDATE, 'YYYY-MM-DD-HH.MM.SS')||chr(30)||
              'CURR_RATE'||chr(31)||'1'||chr(30)||
              'VOUCHER_DATE'||chr(31)||TO_CHAR(SYSDATE, 'YYYY-MM-DD-HH.MM.SS')||chr(30)||
              'USERID'||chr(31)||'IFSGFT'||chr(30)||
              'USER_GROUP'||chr(31)||'AC'||chr(30)||
              'VOUCHER_TYPE'||chr(31)||'U'||chr(30)||
              'PAYMENT_TYPE_CODE'||chr(31)||'Comp Fornecedor'||chr(30)||
              'CURRENCY'||chr(31)||r_Adiantamento.CURRENCY||chr(30)||
              'CURR_RATE_TYPE'||chr(31)||'1'||chr(30)||
              'CURR_RATE'||chr(31)||'1'||chr(30)||
              'TAX_CURR_RATE'||chr(31)||'1'||chr(30)||
              'PREL_PAYMENT_ID'||chr(31)||prel_payment_id_||chr(30)||
              'ACCOUNTING_YEAR'||chr(31)||TO_CHAR(SYSDATE, 'YYYY')||chr(30)||
              'NOTE_ID'||chr(31)||''||chr(30);

              IFSGFT.PREL_PAYMENT_API.NEW__( p0_ , p1_ , p2_ , p3_ , 'DO' );
       p0_ := NULL;
       p1_ := NULL;
       p2_ := NULL;
       p3_ := NULL;

       p3_ := 'COMPANY'||chr(31)||r_Adiantamento.COMPANY||chr(30)||
              'SERIES_ID'||chr(31)||''||chr(30)||
              'PAYMENT_ID'||chr(31)||''||chr(30)||
              'CURRENCY'||chr(31)||r_Adiantamento.CURRENCY||chr(30)||
              'DIV_FACTOR'||chr(31)||'1'||chr(30)||
              'CURR_RATE'||chr(31)||'1'||chr(30)||
              'TAX_CURR_RATE'||chr(31)||'1'||chr(30)||
              'PREL_PAYMENT_ID'||chr(31)||prel_payment_id_||chr(30)||
              'PAYMENT_DATE'||chr(31)||TO_CHAR(SYSDATE, 'YYYY-MM-DD-HH.MM.SS')||chr(30);

       IFSGFT.PREL_PAYMENT_PER_CURRENCY_API.NEW__( p0_ , p1_ , p2_ , p3_ , 'DO' );
      transaction_sys.set_status_info('Compensação Criada: '||prel_payment_id_||'.','INFO');
    COMMIT;
-----------------------------------------------------------------------------------------------------------------
   --Inclusão dos titulos na compensação

        BEGIN
          transaction_sys.set_status_info('Inserindo titulo de Adiantamento ID: '||r_Adiantamento.LEDGER_ITEM_SERIES_ID||' N Titulo: '||r_Adiantamento.LEDGER_ITEM_ID||' Id Pagamento: '||prel_payment_id_||'.','INFO');
  -- p0_ FLOAT := 67721;

   p1_  := r_Adiantamento.COMPANY;
-- Identação recebida pelo objeto Store_Prel_Pay_Trans, não alterar a identação.
   p2_ := '!
$1='||r_Adiantamento.IDENTITY||'
$2=Fornecedor
$3='||r_Adiantamento.LEDGER_ITEM_SERIES_ID||'
$4='||r_Adiantamento.LEDGER_ITEM_ID||'
$5=1
$6=1
$8='||r_Adiantamento.VALOR_ABERTO||'
$Z=END
';

   p3_ := 'OFFSET';
-- Identação recebida pelo objeto Store_Prel_Pay_Trans, não alterar a identação.
   p4_ := '!
$CURRENCY='||r_Adiantamento.CURRENCY||'
$DOM_CURR='||r_Adiantamento.CURRENCY||'
$INVERTED_RATE=FALSE
$DEC_IN_CURR_AMT=2
$DISC_PARTIAL_PAY=FALSE
$DIV_FACTOR=1
$PARKED_PAY_TYPE=Fornecedor
$PAYMENT_DATE='||TO_CHAR(SYSDATE, 'YYYY-MM-DD-HH.MM.SS')||'
$POST_PREL_TAX_WITHH=
$CURR_RATE=1
$USE_TAX_INV=FALSE
$TAX_CURR_RATE=1
';


    IFSGFT.Log_SYS.Init_Debug_Session_('bp');

IFSGFT.PREL_PAYMENT_TRANS_UTIL_API.Store_Prel_Pay_Trans(prel_payment_id_,p1_,p2_,p3_,p4_);
COMMIT;
transaction_sys.set_status_info('Titulo de Adiantamento inserido, ID: '||r_Adiantamento.LEDGER_ITEM_SERIES_ID||' N Titulo: '||r_Adiantamento.LEDGER_ITEM_ID||' Id Pagamento: '||prel_payment_id_||'.','INFO');
END;
         -- Fim da inclusão dos titulos na compensação
-----------------------------------------------------------------------------------------------------------------
CLOSE c_Adiantamento;

END;
