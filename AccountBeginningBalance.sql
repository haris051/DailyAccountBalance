
/*Daily_Account_Balance*/

drop table  if Exists Daily_Account_Balance;


create table Daily_Account_Balance(
                                    id int primary key auto_increment,
                                    AccountId int,
									Debit Double,
									Credit Double,
                                    Balance Double,
                                    EntryDate Date,
                                    foreign key(AccountId) references accounts_id(id) on delete cascade,
                                    unique key(AccountId,EntryDate)
                                  );
                                


drop FUNCTION  if Exists FUNC_SET_DAILY_ACCOUNT_BALANCE;

DELIMITER $$

create function FUNC_SET_DAILY_ACCOUNT_BALANCE(accountId int,amount double,glFlag int,entryDate Text)
returns Text
READS SQL DATA
DETERMINISTIC
BEGIN

Declare getAccountType int;
Declare debitCreditFlag Text;
Declare OpenningBalanceFlag Text;

if 
    accountId =null
	then
		return 'accountID is null';
elseif
    glFlag=null
	then
		return 'GLFLAG is null';
elseif
    entryDate ='' or 
    entryDate=null
	then return 'EntryDate is NULL';	
end if;


select      account_type.ACCOUNT_ID into getAccountType
from        accounts_id 
inner join  account_type 
on 
			account_type.id=accounts_id.ACCOUNT_TYPE_ID 
where 
			accounts_id.id=accountId;


if
        getAccountType = '' or
        getAccountType is null
        then
        return 'Account Type is Null';
    
end if;


if 
		glFlag = 15 OR glFLAG = '511' OR glFlag= 20 OR glFlag=31 OR glFlag=34 OR 
		glFlag=38 OR glFlag=40 OR glFlag=42 OR glFlag=44 OR 
		glFlag=79 OR glFlag=80 OR glFlag=81 OR glFlag=46 OR 
		glFlag=47 OR glFlag=50 OR glFlag=51 OR glFlag=54 OR 
		glFlag=56 OR glFlag=86 OR glFlag=87 OR glFlag=85 OR 
		glFlag=58 OR glFlag=60 OR glFlag=150 OR glFlag=151 OR 
		glFlag=62 OR glFlag=65 OR glFlag=70 OR glFlag=68 OR 
		glFlag=72 OR glFlag=73 OR glFlag=76 OR glFlag=77 OR 
		glFlag=78 OR glFlag=101 OR glFlag=23 OR glFlag=104 OR 
		glFlag=29  OR glFlag=109 OR glFlag=111 OR 
		glFlag=114 OR glFlag=106  OR glFlag=108 or glFlag= 5551 OR glFlag= 201 or glFlag = '511'
		OR glFlag=28 OR glFlag = 204
    
    then
		set debitCreditFlag = 'Credit';
elseif 
		glFlag = 16 OR glFlag = '510' OR glFlag =19 OR glFlag =32 OR glFlag =33 OR 
		glFlag =37 OR glFlag =39 OR glFlag =41 OR glFlag =43 OR 
		glFlag =45 OR glFlag =48 OR glFlag =82 OR glFlag =83 OR 
		glFlag =84 OR glFlag =49 OR glFlag =52 OR glFlag =100 OR 
		glFlag =53 OR glFlag =55 OR glFlag =57 OR glFlag =59 OR 
		glFlag =64 OR glFlag =66 OR glFlag =69 OR glFlag =67 OR 
		glFlag =71 OR glFlag =74 OR glFlag =75 OR glFlag =26 OR glFlag =205 OR
		glFlag =102 OR glFlag = 203 OR glFlag =103 OR glFlag =105 OR glFlag =112 OR 
		glFlag =107 OR glFlag =110 OR glFlag =113    OR glFlag= '5552'OR glFlag= '510'
     then
		set debitCreditFlag = 'Debit';
elseif
	glFlag=5555
	 then
		set OpenningBalanceFlag = 'OpenningBalance';
		
end if;

if OpenningBalanceFlag = 'OpenningBalance'
	then
		if 
		  getAccountType = 3 OR 
		  getAccountType = 2 OR 
		  getAccountType = 5 
		  then 
		  
				insert 
						into Daily_Account_Balance(AccountId,Debit,Credit,Balance,EntryDate) 
						values(
								accountId,
								case when amount>0 then amount else 0 end,
								case when amount<0 then amount * -1 else 0 end,
								amount,
								convert(entryDate,date)
							  );
	 elseif 
		  getAccountType = 1 OR 
		  getAccountType = 4 OR 
		  getAccountType = 6
		  then 
				insert 
						into Daily_Account_Balance(AccountId,Debit,Credit,Balance,EntryDate) 
						values(
								accountId,
								case when amount<0 then amount * -1 else 0 end,
								case when amount>0 then amount else 0 end,
								amount,
								convert(entryDate,date)
							  );
	end if;
					
        return '';
end if;


if 
	getAccountType = 3 or 
	getAccountType = 2 or 
    getAccountType = 5 
    then
		if
		  debitCreditFlag='Debit'
				then
					insert into Daily_Account_Balance(AccountId,Debit,Credit,Balance,EntryDate) values(accountId,amount,0,amount,convert(entryDate,date))
					on duplicate key update Balance=Balance+amount,Debit=Debit+amount;
                    return '';
				else
					insert into Daily_Account_Balance(AccountId,Debit,Credit,Balance,EntryDate) values(accountId,0,amount,amount*-1,convert(entryDate,date))
					on duplicate key update Balance=Balance-amount,Credit=Credit+amount;
                    return '';
		end if;
elseif 
	  getAccountType = 1 or 
	  getAccountType = 4 or 
      getAccountType = 6
		then
			if 
			  debitCreditFlag = 'Debit'
              then
				  insert into Daily_Account_Balance(AccountId,DEBIT,CREDIT,Balance,EntryDate) values(accountId,amount,0,amount*-1,convert(entryDate,date))
				  on duplicate key update Balance=Balance-amount,DEBIT = DEBIT + amount;
                  return '';
			  else
				  insert into Daily_Account_Balance(AccountId,DEBIT,CREDIT,Balance,EntryDate) values(accountId,0,amount,amount,convert(entryDate,date))
				  on duplicate key update Balance=Balance+amount,CREDIT = CREDIT + amount;
                  return '';
			end if;
end if;
END$$
DELIMITER ;

select FUNC_SET_DAILY_ACCOUNT_BALANCE(GL_ACC_ID,Amount,GL_FLAG,FORM_DATE) from sales_accounting;
select FUNC_SET_DAILY_ACCOUNT_BALANCE(GL_ACC_ID,Amount,GL_FLAG,FORM_DATE) from purchase_accounting;
select FUNC_SET_DAILY_ACCOUNT_BALANCE(GL_ACC_ID,Amount,GL_FLAG,FORM_DATE) from payments_accounting;
select FUNC_SET_DAILY_ACCOUNT_BALANCE(GL_ACC_ID,Amount,GL_FLAG,FORM_DATE) from repair_accounting;
select FUNC_SET_DAILY_ACCOUNT_BALANCE(GL_ACC_ID,Amount,GL_FLAG,FORM_DATE) from adjustment_accounting;
select FUNC_SET_DAILY_ACCOUNT_BALANCE(GL_ACC_ID,Amount,GL_FLAG,FORM_DATE) from stock_accounting;
select FUNC_SET_DAILY_ACCOUNT_BALANCE(accounts_id.ID,accounts_id.Beginning_BALANCE,5555,accounts_id.ENTRY_DATE) from accounts_id;
