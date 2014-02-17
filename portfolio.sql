create table new_data (symbol varchar(16) not null, timestamp number not null, open number not null, high number not null, low number not null, close number not null, volume number not null, primary key(symbol, timestamp));
create view all_data as (select * from new_data) union all (select * from cs339.stocksdaily);
create table portfolio_user (email varchar(64) not null primary key, constraint good_email CHECK (email LIKE '%@%'), password VARCHAR(64) NOT NULL, constraint long_password CHECK (password LIKE '________%'));
create table portfolio (name VARCHAR(64) not null, user_email VARCHAR(64) not null references portfolio_user(email), cash_balance number NOT NULL, primary key(name, user_email));
create table users_stock (portfolio_name VARCHAR(64) not null, user_email VARCHAR(64) not null, symbol VARCHAR(64) not null, quantity number not null, primary key(portfolio_name, symbol, user_email), foreign key (portfolio_name, user_email) references portfolio(name, user_email));
quit;