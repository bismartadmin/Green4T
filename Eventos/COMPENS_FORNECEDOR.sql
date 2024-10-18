CREATE OR REPLACE PROCEDURE COMPENS_FORNECEDOR (attr_ IN VARCHAR2) IS

prel_payment_id_ FLOAT := NULL;
p0_ VARCHAR2(32000) := NULL;
p1_ VARCHAR2(32000) := NULL;
p2_ VARCHAR2(32000) := NULL;
p3_ VARCHAR2(32000) := NULL;
currency_ varchar2(3200):= client_sys.Get_Item_Value('currency',attr_); 
identity_  varchar2(3200):= client_sys.Get_Item_Value('identity',attr_);
company_ varchar2(3200):= client_sys.Get_Item_Value('company',attr_);


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
and PARKED_PAY_TYPE = 'Supplier' 
and LEDGER_ITEM_SERIES_ID = 'SI'
--and LEDGER_ITEM_ID like 'ADD%'
and REST_AMOUNT > 0
and decode(IFSGFT.Payment_Proposal_API.Is_Invoice_Used_In_Proposals2(COMPANY, IDENTITY, PARTY_TYPE, LEDGER_ITEM_SERIES_ID, LEDGER_ITEM_ID, LEDGER_ITEM_VERSION,INSTALLMENT_ID)
     ,'TRUE','TRUE',IFSGFT.Payment_Order_API.Is_Invoice_Used_In_Orders2(COMPANY, IDENTITY, PARTY_TYPE, LEDGER_ITEM_SERIES_ID, LEDGER_ITEM_ID, LEDGER_ITEM_VERSION,INSTALLMENT_ID)) = 'FALSE'
and CURRENCY = currency_
and COMPANY = company_     
and (IDENTITY = identity_ ) --15683153840
FETCH FIRST 1 ROW ONLY;

r_Adiantamento c_Adiantamento%ROWTYPE;


BEGIN
   /* OPEN c_Adiantamento;
     LOOP
        FETCH c_Adiantamento INTO r_Adiantamento;
        EXIT WHEN c_Adiantamento%notfound;
     END LOOP;
    CLOSE c_Adiantamento;  */
    --RAISE_APPLICATION_ERROR(-20100,'Antes do for: '||currency_||', '||identity_||', '||company_);
  FOR R IN c_Adiantamento
   LOOP  
     RAISE_APPLICATION_ERROR(-20100,'Antes do IF: '||R.IDENTITY||' '||currency_||', '||identity_||', '||company_);   
    IF R.IDENTITY IS NOT NULL THEN 
      RAISE_APPLICATION_ERROR(-20100,'Depois do IF: '||R.IDENTITY||', '||currency_||', '||identity_||', '||company_);
       prel_payment_id_ := IFSGFT.PREL_PAYMENT_API.Get_Prel_Payment_Id;
       p3_ := 'COMPANY'||chr(31)||R.COMPANY||chr(30)||
              'PAY_DATE'||chr(31)||TO_CHAR(SYSDATE, 'YYYY-MM-DD-HH.MM.SS')||chr(30)||
              'CURR_RATE'||chr(31)||'1'||chr(30)||
              'VOUCHER_DATE'||chr(31)||TO_CHAR(SYSDATE, 'YYYY-MM-DD-HH.MM.SS')||chr(30)||
              'USERID'||chr(31)||'IFSGFT'||chr(30)||
              'USER_GROUP'||chr(31)||'AC'||chr(30)||
              'VOUCHER_TYPE'||chr(31)||'U'||chr(30)||
              'PAYMENT_TYPE_CODE'||chr(31)||'Supplier Offset'||chr(30)||
              'CURRENCY'||chr(31)||R.CURRENCY||chr(30)||
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
       
       p3_ := 'COMPANY'||chr(31)||R.COMPANY||chr(30)||
              'SERIES_ID'||chr(31)||''||chr(30)||
              'PAYMENT_ID'||chr(31)||''||chr(30)||
              'CURRENCY'||chr(31)||R.CURRENCY||chr(30)||
              'DIV_FACTOR'||chr(31)||'1'||chr(30)||
              'CURR_RATE'||chr(31)||'1'||chr(30)||
              'TAX_CURR_RATE'||chr(31)||'1'||chr(30)||
              'PREL_PAYMENT_ID'||chr(31)||prel_payment_id_||chr(30)||
              'PAYMENT_DATE'||chr(31)||TO_CHAR(SYSDATE, 'YYYY-MM-DD-HH.MM.SS')||chr(30); 
              
       IFSGFT.PREL_PAYMENT_PER_CURRENCY_API.NEW__( p0_ , p1_ , p2_ , p3_ , 'DO' );  
       --Dbms_Output.Put_Line('Id pagamento: '||prel_payment_id_||', p0: '||p0_||', p1: '||p1_||', p2: '||p2_||', p3: '||p3_);     
    COMMIT;
    ELSE
       DBMS_OUTPUT.PUT_LINE('Não existe Adiantamento para o Fornecedor: '||R.IDENTITY||'.');
       RAISE_APPLICATION_ERROR(-20100,'Depois do Else: '||R.IDENTITY||', '||currency_||', '||identity_||', '||company_);
     --  EXIT;
    END IF; 
   END LOOP;  
          
END;