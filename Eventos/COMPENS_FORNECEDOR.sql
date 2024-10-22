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
invoice_id_ varchar2(3200):= client_sys.Get_Item_Value('invoice_id',attr_);
invoice_no_ varchar2(3200):= client_sys.Get_Item_Value('invoice_no',attr_);
series_id_  varchar2(3200):= client_sys.Get_Item_Value('series_id',attr_);
amount_ varchar2(3200):= client_sys.Get_Item_Value('amount',attr_);


CURSOR c_Adiantamento IS
select COMPANY, LEDGER_ITEM_SERIES_ID, LEDGER_ITEM_ID, IDENTITY, CURRENCY, IS_INVOICE, FULL_AMOUNT VALOR, REST_AMOUNT VALOR_ABERTO
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
    
        --- Aprovação do título
        BEGIN
         transaction_sys.set_status_info('Iniciando aprovaçao do titulo: '||invoice_id_||' N Titulo: '||invoice_no_||'.','INFO');
            BEGIN
              --   p0_ := company_;
               --  p1_ := invoice_id_;
    
                IFSGFT.Invoice_API.Update_Pl_Pay_Date(company_ , invoice_id_);
                COMMIT;
            END;
            BEGIN
                p0_  := '';
                p1_  := NULL;
                p2_  := NULL;
                p3_  := 'AUTHORIZED'||chr(31)||'TRUE'||chr(30)||'AUTHORIZED'||chr(31)||'TRUE'||chr(30);
           --     p4_  := ;

                SELECT OBJID, OBJVERSION into p1_, p2_ FROM PAYMENT_PLAN_AUTH_QRY WHERE INVOICE_NO = invoice_no_;
    
                IFSGFT.Log_SYS.Init_Debug_Session_('bp');
                IFSGFT.PAYMENT_PLAN_AUTH_API.MODIFY__( p0_ , p1_ , p2_ ,p3_,'DO');
                COMMIT;   
            END;
          transaction_sys.set_status_info('Titulo aprovado: '||invoice_id_||' N Titulo: '||invoice_no_||'.','INFO');  
        END;
        --- Fim da Aprovação do Titulo  
    
    
    
       --Inclusão do título de Adiantamento 

        BEGIN
          transaction_sys.set_status_info('Inserindo titulo de Adiantamento ID: '||r_Adiantamento.LEDGER_ITEM_SERIES_ID||' N Titulo: '||r_Adiantamento.LEDGER_ITEM_ID||' Id Pagamento: '||prel_payment_id_||'.','INFO');
  -- p0_ FLOAT := 67721;

   p1_  := company_;
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
    -- Fim da Inclusão do título de Adiantamento 
         
    -- Inclusão do título de reembolso   
        BEGIN
          transaction_sys.set_status_info('Inserindo titulo de Reembolso ID: '||series_id_||' N Titulo: '||invoice_no_||' Id Pagamento: '||prel_payment_id_||' Valor: '||amount_||'.','INFO');

          -- p0_ FLOAT := 67721;
          p1_  := company_;
-- Identação recebida pelo objeto Store_Prel_Pay_Trans, não alterar a identação.
   p2_ := '!
$1='||identity_||'
$2=Fornecedor
$3='||series_id_||'
$4='||invoice_no_||'
$5=1
$6=1
$8='||amount_||'
$Z=END
';

        p3_ := 'OFFSET';
-- Identação recebida pelo objeto Store_Prel_Pay_Trans, não alterar a identação.
   p4_ := '!
$CURRENCY='||currency_||'
$DOM_CURR='||currency_||'
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
        transaction_sys.set_status_info('Titulo de Reembolso inserido, ID: '||series_id_||' N Titulo: '||invoice_no_||' Id Pagamento: '||prel_payment_id_||'.','INFO');
    END;            

CLOSE c_Adiantamento;

END;
