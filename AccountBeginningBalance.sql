
/*
drop table  if Exists Daily_Account_Balance;


create table Daily_Account_Balance(
                                    id int not null primary key auto_increment,
                                    AccountId int,
				    Debit DECIMAL(22,2),
				    Credit DECIMAL(22,2),
                                    Balance DECIMAL(22,2),
                                    EntryDate Date,
                                    foreign key(AccountId) references accounts_id(id) on delete cascade,
                                    INDEX (AccountId),
				    INDEX (EntryDate),
				    INDEX (id)
                                  );
  */

Alter Table daily_account_balance   
drop foreign key daily_account_balance_ibfk_1;                               
                                  
Alter Table daily_account_balance
Drop Constraint AccountId;                                  
                                  
Alter Table Daily_Account_Balance 
Add Constraint Unique_Id Unique(id);


Alter Table Daily_Account_Balance
Add index Index_Account_Id (AccountId);

Alter Table Daily_Account_Balance
Add index Index_Entry_Date (EntryDate);

Alter Table Daily_Account_Balance
Add index Index_id(id);

Alter Table daily_account_balance
Add constraint AccountId_ForeignKey Foreign key(AccountId) references accounts_id(id) on delete cascade;

Alter table daily_account_balance
Add Constraint DAILY_ACCOUNT_BALANCE_UNIQUE Unique key(`ACCOUNTID`,`ENTRYDATE`);


drop FUNCTION  if Exists FUNC_SET_DAILY_ACCOUNT_BALANCE;

DELIMITER $$

create function FUNC_SET_DAILY_ACCOUNT_BALANCE(accountId int,AMOUNT DECIMAL(22, 2),glFlag int,entryDate Text)
returns Text
READS SQL DATA
DETERMINISTIC
BEGIN

	Declare getAccountType int;
	Declare debitCreditFlag Text;
	Declare OpenningBalanceFlag Text;
	Declare Unique_AccountId_EntryDate_PrimaryKey int;

	if  accountId is null
		then
			return 'accountID is null';
	elseif glFlag is null
		then
			return 'GLFLAG is null';
	elseif
		entryDate ='' or 
		entryDate is null
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
			glFlag = 511 OR glFlag = 15 OR glFlag = 512 OR glFlag= 20 OR
			glFlag = 31 OR glFlag = 34 OR glFlag = 38 OR glFlag = 40  OR 
			glFlag = 42 OR glFlag = 44 OR glFlag = 79 OR glFlag =80  OR 
			glFlag = 81 OR glFlag = 46 OR glFlag = 47 OR glFlag =50 OR 
			glFlag = 51 OR glFlag = 54 OR glFlag = 56 OR glFlag = 86 OR 
			glFlag = 87 OR glFlag = 85 OR glFlag = 58 OR glFlag = 60 OR 
			glFlag = 150 OR glFlag = 151 OR glFlag = 62 OR glFlag = 65 OR 
			glFlag = 68 OR glFlag = 70 OR glFlag = 72 OR glFlag = 73 OR 
			glFlag = 76 OR glFlag = 78 OR glFlag = 77 OR glFlag = 101 OR 
			glFlag = 23 OR glFlag = 102 OR glFlag = 104 OR glFlag = 106 OR
			glFlag = 5554 OR glFlag = 29 OR glFlag = 28 OR glFlag = 108 OR 
			glFlag = 109 OR glFlag = 111 OR glFlag = 114 OR glFlag = 5552 OR 
			glFlag = 115 OR glFlag = 90 OR glFLAG = 5557 OR glFlag = 5558
		
		then
			set debitCreditFlag = 'Credit';
	elseif 

			glFlag = 510 OR glFlag = 16 OR glFlag = 513 OR glFlag = 19 OR 
			glFlag = 32 OR glFlag =33 OR glFlag = 37 OR glFlag =39 OR 
			glFlag =41 OR glFlag =43 OR glFlag =45 OR glFlag =48 OR 
			glFlag =82 OR glFlag =83 OR glFlag =84 OR glFlag = 49 OR 
			glFlag = 52 OR glFlag = 100 OR glFlag =53 OR glFlag = 55 OR 
			glFlag = 57 OR glFlag = 59 OR glFlag = 64 OR glFlag = 66 OR 
			glFlag = 67 OR glFlag = 69 OR glFlag = 71 OR glFlag = 74 OR 
			glFlag = 75 OR glFlag = 26 OR glFlag = 201 OR glFlag = 203 OR 
			glFlag = 103 OR glFlag = 105 OR glFlag = 5553 OR glFlag = 107 OR 
			glFlag = 204 OR glFlag = 205 OR glFlag = 110 OR glFlag = 113 OR 
			glFlag = 112 OR glFlag = 5551 OR glFlag = 89 OR glFlag =116 OR 
			glFlag = 117  OR glFlag = 5556 OR glFlag = 5559
			
			
		 then
			set debitCreditFlag = 'Debit';
	elseif
		glFlag = 5555 OR glFlag = -5555
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
					select A.id INTO Unique_AccountId_EntryDate_PrimaryKey 
					from Daily_Account_Balance as A
					where A.AccountId = accountId 
					and Convert(A.EntryDate,Date) = convert(entryDate,Date);
					
					if(Unique_AccountId_EntryDate_PrimaryKey is null or Unique_AccountId_EntryDate_PrimaryKey = '')
					   then 
					   
							IF (amount >= 0)
							THEN
					   
							   insert into Daily_Account_Balance(AccountId,Debit,Credit,Balance,EntryDate) 
								values(
										accountId,
										amount,
										0,
										amount,
										convert(entryDate,date)
									   );
									   
							ELSE 
							
								insert into Daily_Account_Balance(AccountId,Debit,Credit,Balance,EntryDate) 
								values(
										accountId,
										0,
										amount * -1,
										amount,
										convert(entryDate,date)
									   );
									   
							END IF;
							
						else 
							
							IF (glFlag = 5555)
							THEN
							
								IF (amount >= 0)
                                THEN
                            
									 update Daily_Account_Balance
									 SET    Balance = Balance + amount,
											Debit = Debit + amount
									 where id = Unique_AccountId_EntryDate_PrimaryKey;
                                     
								 ELSE
                                 
									update Daily_Account_Balance
									 SET    Balance = Balance + amount,
											credit = credit + amount * -1
									 where id = Unique_AccountId_EntryDate_PrimaryKey;
                                     
								 END IF;
								 
							ELSE
							
								IF (amount >= 0)
                                THEN
                            
									update Daily_Account_Balance
									 SET    Balance = Balance - amount,
											Debit = Debit - amount
									 where id = Unique_AccountId_EntryDate_PrimaryKey;
                                     
								 ELSE
                                 
									update Daily_Account_Balance
									 SET    Balance = Balance - amount,
											credit = credit - amount * -1
									 where id = Unique_AccountId_EntryDate_PrimaryKey;
                                     
								 END IF;
								 
							 END IF;
							 
					end if;
					
		 elseif 
			  getAccountType = 1 OR 
			  getAccountType = 4 OR 
			  getAccountType = 6
			  then 
			  
					select A.id INTO Unique_AccountId_EntryDate_PrimaryKey 
					from Daily_Account_Balance as A
					where A.AccountId = accountId 
					and Convert(A.EntryDate,Date) = convert(entryDate,Date);
					
					if(Unique_AccountId_EntryDate_PrimaryKey is null or Unique_AccountId_EntryDate_PrimaryKey = '')
						then 
						
							IF (amount >= 0)
							THEN
							
								insert	into Daily_Account_Balance(AccountId,Debit,Credit,Balance,EntryDate) 
								values(
										accountId,
										0,
										amount,
										amount,
										convert(entryDate,date)
									   );
									   
							ELSE
							
								insert	into Daily_Account_Balance(AccountId,Debit,Credit,Balance,EntryDate) 
								values(
										accountId,
										amount * -1,
										0,
										amount,
										convert(entryDate,date)
									   );
									   
							END IF;
							
						else 
                        
							IF (glFlag = 5555)
							THEN
						
								IF (amount >= 0)
								THEN
							
									update Daily_Account_Balance 
									SET    Balance = Balance + amount,
										   credit = credit + amount
									where id = Unique_AccountId_EntryDate_PrimaryKey;
									
								ELSE
								
									update Daily_Account_Balance 
									SET    Balance = Balance + amount,
										   Debit = Debit + amount * -1
									where id = Unique_AccountId_EntryDate_PrimaryKey;
									
								END IF;
                                
							ELSE
                            
								IF (amount >= 0)
								THEN
							
									update Daily_Account_Balance
									 SET    Balance = Balance - amount,
											credit = credit - amount
									 where id = Unique_AccountId_EntryDate_PrimaryKey;
									 
								 ELSE
								 
									update Daily_Account_Balance
									 SET    Balance = Balance - amount,
											Debit = Debit - amount * -1
									 where id = Unique_AccountId_EntryDate_PrimaryKey;
									 
								 END IF;
                            
                            END IF;
							
					end if;
						
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
						
						select A.id INTO Unique_AccountId_EntryDate_PrimaryKey 
						from Daily_Account_Balance as A 
						where A.AccountId = accountId 
						and Convert(A.EntryDate,Date) = convert(entryDate,Date);
							
						if (Unique_AccountId_EntryDate_PrimaryKey is null or Unique_AccountId_EntryDate_PrimaryKey = '')
							then 
								insert into Daily_Account_Balance(AccountId,Debit,Credit,Balance,EntryDate) 
								values(accountId,amount,0,amount,convert(entryDate,date));	
							else 
								update Daily_Account_Balance SET Balance=Balance+amount,Debit=Debit+amount where id = Unique_AccountId_EntryDate_PrimaryKey;
								
						end if;
						
						return '';
					else
					
						select A.id INTO Unique_AccountId_EntryDate_PrimaryKey 
						from Daily_Account_Balance as A 
						where A.AccountId = accountId 
						and Convert(A.EntryDate,Date) = convert(entryDate,Date);

						if(Unique_AccountId_EntryDate_PrimaryKey is null or Unique_AccountId_EntryDate_PrimaryKey = '')
							then 
								insert into Daily_Account_Balance(AccountId,Debit,Credit,Balance,EntryDate) values(accountId,0,amount,amount*-1,convert(entryDate,date));
							else 
								update Daily_Account_Balance SET Balance=Balance-amount,Credit=Credit+amount where id = Unique_AccountId_EntryDate_PrimaryKey;
						end if;
						
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
					  
					  select A.id INTO Unique_AccountId_EntryDate_PrimaryKey 
					  from Daily_Account_Balance as A 
					  where A.AccountId = accountId 
					  and Convert(A.EntryDate,Date) = convert(entryDate,Date);
					  
					  if(Unique_AccountId_EntryDate_PrimaryKey is null or Unique_AccountId_EntryDate_PrimaryKey = '')
							then 
								insert into Daily_Account_Balance(AccountId,DEBIT,CREDIT,Balance,EntryDate) values(accountId,amount,0,amount*-1,convert(entryDate,date));
							else 
								update Daily_Account_Balance SET Balance=Balance-amount,DEBIT = DEBIT + amount where id = Unique_AccountId_EntryDate_PrimaryKey;
					  end if;
					  
					  return '';
				  else
					  select A.id INTO Unique_AccountId_EntryDate_PrimaryKey 
					  from Daily_Account_Balance as A  
					  where A.AccountId = accountId 
					  and Convert(A.EntryDate,Date) = convert(entryDate,Date);
					  
					  if(Unique_AccountId_EntryDate_PrimaryKey is null or Unique_AccountId_EntryDate_PrimaryKey = '')
							then
								insert into Daily_Account_Balance(AccountId,DEBIT,CREDIT,Balance,EntryDate) values(accountId,0,amount,amount,convert(entryDate,date));
							else 
								update Daily_Account_Balance SET Balance=Balance+amount,CREDIT = CREDIT + amount where id =Unique_AccountId_EntryDate_PrimaryKey;
					  end if;
					 
					  return '';
				end if;
	end if;
	
END$$
DELIMITER ;

/*
select FUNC_SET_DAILY_ACCOUNT_BALANCE(GL_ACC_ID,Amount,GL_FLAG,FORM_DATE) from sales_accounting;
select FUNC_SET_DAILY_ACCOUNT_BALANCE(GL_ACC_ID,Amount,GL_FLAG,FORM_DATE) from purchase_accounting;
select FUNC_SET_DAILY_ACCOUNT_BALANCE(GL_ACC_ID,Amount,GL_FLAG,FORM_DATE) from payments_accounting;
select FUNC_SET_DAILY_ACCOUNT_BALANCE(GL_ACC_ID,Amount,GL_FLAG,FORM_DATE) from repair_accounting;
select FUNC_SET_DAILY_ACCOUNT_BALANCE(GL_ACC_ID,Amount,GL_FLAG,FORM_DATE) from adjustment_accounting;
select FUNC_SET_DAILY_ACCOUNT_BALANCE(GL_ACC_ID,Amount,GL_FLAG,FORM_DATE) from stock_accounting;
select FUNC_SET_DAILY_ACCOUNT_BALANCE(accounts_id.ID,accounts_id.Beginning_BALANCE,5555,accounts_id.ENTRY_DATE) from accounts_id;
*/
