create or replace PROCEDURE COMPENS_FORNECEDOR (attr_ IN VARCHAR2) IS

prel_payment_id_ FLOAT := NULL;
p0_ VARCHAR2(32000) := NULL;
p1_ VARCHAR2(32000) := NULL;
p2_ VARCHAR2(32000) := NULL;
p3_ VARCHAR2(32000) := NULL;
p4_ VARCHAR2(32000) := NULL;
p5_ VARCHAR2(32000) := NULL;
p6_ FLOAT           := NULL;
p8_ VARCHAR2(32000) := NULL;
p9_ FLOAT           := NULL;
p10_ FLOAT          := NULL;
val_adiantamento_ NUMBER := NULL;
val_reembolso_    NUMBER := NULL;
serie_id_aprov_ VARCHAR2(32000) := NULL;
payment_id_ FLOAT := NULL;
voucher_type_ VARCHAR2(32000) := NULL;
acc_year_ FLOAT := NULL;
voucher_no_ FLOAT := NULL;
curr_amount_ FLOAT := NULL;


tax_p0_ VARCHAR2(32000) := NULL;
tax_p1_ FLOAT := NULL;
tax_p2_ VARCHAR2(32000) := NULL;
tax_p3_ VARCHAR2(32000) := NULL;
tax_p4_ VARCHAR2(32000) := NULL;
tax_p5_ VARCHAR2(32000) := NULL;
tax_p6_ VARCHAR2(32000) := NULL;
tax_p7_ FLOAT := NULL;
tax_p8_ FLOAT := NULL;
tax_p9_ FLOAT := NULL;
tax_p10_ DATE := NULL;
tax_p11_ FLOAT := NULL;
tax_p12_ FLOAT := NULL;


                        

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
      transaction_sys.set_status_info('Compensação Criada: '||prel_payment_id_||' series: '||series_id_||'.','INFO');
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
        -- Fim da Inclusão do título de reembolso

        -- Bloco Ajustes do valor da compensação
    BEGIN
        transaction_sys.set_status_info('Ajustes do saldo: '||series_id_||' N Titulo: '||invoice_no_||' Id Pagamento: '||prel_payment_id_||'.','INFO');
        --Trazer o valor do adiantamento 
        select abs(PAYMENT_AMOUNT) into val_adiantamento_ from PREL_PAYMENT_TRANS 
            where PREL_PAYMENT_ID = prel_payment_id_
            and LEDGER_ITEM_SERIES_ID = r_Adiantamento.LEDGER_ITEM_SERIES_ID;

        --Trazer o valor do reembolso  
        select PAYMENT_AMOUNT into val_reembolso_ from PREL_PAYMENT_TRANS
            where PREL_PAYMENT_ID = prel_payment_id_
            and LEDGER_ITEM_SERIES_ID = series_id_;

        IF val_reembolso_ >  val_adiantamento_ THEN
            transaction_sys.set_status_info('Iniciando ajustes do saldo, adiantamento: '||val_adiantamento_||' Reembolso: '||val_reembolso_||'.','INFO');
            BEGIN
                FOR r in (select OBJID, OBJVERSION from PREL_PAYMENT_TRANS 
                            where PREL_PAYMENT_ID = prel_payment_id_
                              and LEDGER_ITEM_SERIES_ID = series_id_ 
                              and LEDGER_ITEM_ID = invoice_no_
                            FETCH FIRST 1 ROW ONLY)
                LOOP
                    BEGIN
                        tax_p0_  := '!PAY_TAX_ITEMS';
                        tax_p1_  := NULL;
                        tax_p2_  := company_;
                        tax_p3_  := identity_;
                        tax_p4_  := 'Fornecedor';
                        tax_p5_  := series_id_;
                        tax_p6_  := invoice_no_;
                        tax_p7_  := 1;
                        tax_p8_  := 1;
                        tax_p9_  := val_adiantamento_;
                        tax_p10_ := to_date(SYSDATE,'YYYY-MM-DD-HH24.MI.SS','NLS_CALENDAR=GREGORIAN');
                        tax_p11_ := 1;
                        tax_p12_ := 1;

                        IFSGFT.Payment_Tax_Item_API.Create_Def_Pay_Tax_Items( tax_p0_ , tax_p1_ , tax_p2_ , tax_p3_ , tax_p4_ , tax_p5_ , tax_p6_ , tax_p7_ , tax_p8_ , tax_p9_ , tax_p10_ , tax_p11_ , tax_p12_ );
                        COMMIT;
                    END;
                    BEGIN                
                        p0_  := NULL;
                        p1_ := r.OBJID;
                        p2_ := r.OBJVERSION;
                        p3_ := 'PAYMENT_AMOUNT'||chr(31)||val_adiantamento_||chr(30)||
                            'CURR_AMOUNT'||chr(31)||val_adiantamento_||chr(30)||
                            'CURR_REST_AMOUNT'||chr(31)||val_adiantamento_||chr(30); 
                        p4_ := 'DO';       

                        IFSGFT.PREL_PAYMENT_TRANS_API.MODIFY__( p0_ , p1_ , p2_ , p3_ , p4_ );
                        COMMIT;
                    END;
                    BEGIN
                        tax_p0_ := '!PAY_TAX_ITEMS';
                        tax_p1_ := NULL;
                        tax_p2_ := company_;
                        tax_p3_ := identity_;
                        tax_p4_ := 'Fornecedor';
                        tax_p5_ := series_id_;
                        tax_p6_ := invoice_no_;
                        tax_p7_ := 1;
                        p8_     := 'FALSE';
                        
                        IFSGFT.Payment_Tax_Item_API.Save_Pay_Tax_Items( tax_p0_ , tax_p1_ , tax_p2_ , tax_p3_ , tax_p4_ , tax_p5_ , tax_p6_ , tax_p7_ , p8_ );                    
                        COMMIT;
                    END;
                END LOOP;
              transaction_sys.set_status_info('Saldos ajustados.','INFO');  
            END;
        ELSE
           transaction_sys.set_status_info('Saldo não precisa ser ajustado, adiantamento: '||val_adiantamento_||' Reembolso: '||val_reembolso_||'.','INFO'); 
        END IF;
    END;
        -- Fim do bloco Ajustes do valor da compensação.
        
        -- Bloco aprovar Compensação.
    BEGIN
        FOR r IN (SELECT VOUCHER_TYPE,USER_GROUP,ACCOUNTING_YEAR,VOUCHER_GROUP FROM PAYMENT_UNION WHERE PREL_PAYMENT_ID = prel_payment_id_)
        LOOP
            transaction_sys.set_status_info('Iniciando Aprovação da compensacao: '||prel_payment_id_||'.','INFO');
        BEGIN
            p0_ := NULL;
            p1_ := company_;
        
            IFSGFT.PREL_PAYMENT_TRANS_API.Create_Payment_Message(p0_ , p1_ , prel_payment_id_ );    
        END;
        BEGIN
                p0_ := R.VOUCHER_TYPE;
                p1_ := company_;
                p2_ := r.USER_GROUP;
                p6_ := r.ACCOUNTING_YEAR;
                p4_ := r.VOUCHER_GROUP;
                p5_ := 'NOT APPLICABLE';

                IFSGFT.Payment_Library_API.Validate_Voucher_Type_Pay( p0_ , p1_ , p2_ , p6_ , p4_ , p5_ );
        END;
        BEGIN
            serie_id_aprov_ := NULL;
            payment_id_     := NULL;
            p2_             := NULL;
            p6_             := NULL;
            p4_             := company_;
            p3_             := '';

            IFSGFT.PREL_PAYMENT_TRANS_UTIL_API.Copy_Payment_Transactions( serie_id_aprov_ , payment_id_ , p2_ , p6_ , p4_ , prel_payment_id_ ,'OFFSET', p3_ );

            
            voucher_type_ := NULL;
            acc_year_     := NULL;
            voucher_no_   := NULL;
            p5_           := company_;
            p6_           := 0.00;
            curr_amount_  := NULL;
            p8_           := currency_;
            p9_           := 1;
            p10_          := 1;

            IFSGFT.Payment_API.Commit_Manual_Payment(voucher_type_ , acc_year_ , voucher_no_ , serie_id_aprov_ , payment_id_ , p5_ , p6_ , curr_amount_ , p8_ , p9_ , p10_ ,NULL);
    
            IFSGFT.Prel_Payment_Trans_Util_API.Delete_Prel_Pay_Trans( p5_ , prel_payment_id_ , 'OFFSET');
        END;
      END LOOP; 
      transaction_sys.set_status_info('Compensação Aprovada: '||prel_payment_id_||' id_pagamento: '||payment_id_||' voucher_no: '||voucher_no_||'.','INFO');
    END;    

CLOSE c_Adiantamento;

END;
