--An Auction House 
-- i didn't change logical model so i didn't add it in git
-- Drop and create schema
drop schema if exists auction_house cascade;
create schema auction_house;

-- enum for employee_role
do $$
begin
    if not exists (select 1 from pg_type where typname = 'employee_role') then
        create type auction_house.employee_role as enum ('manager', 'auctioneer', 'assistant');
    end if;
end
$$;

--creating table auction

create table auction_house.auction (
    auction_id serial primary key,
    date_time timestamp not null check (date_time > '2000-01-01 00:00:00'),
    location varchar(255) not null
);

--creating table category

create table auction_house.category (
    category_id serial primary key,
    category_name varchar(255) not null unique,
    description text
);

--creating table seller

create table auction_house.seller (
    seller_id serial primary key,
    name varchar(255) not null,
    seller_contact_info varchar(255) not null
);

--creating table buyer

create table auction_house.buyer (
    buyer_id serial primary key,
    name varchar(255) not null,
    buyer_contact_info varchar(255) not null
);

--creating table item

create table auction_house.item (
    item_id serial primary key,
    lot_number varchar(50) not null unique,
    description text not null,
    starting_price decimal(10,2) not null check (starting_price > 0),
    seller_id int not null,
    category_id int,
    foreign key (seller_id) references auction_house.seller(seller_id) on delete cascade, --creating table item
    foreign key (category_id) references auction_house.category(category_id) on delete set null -- retain item if category deleted
);

--creating table auction_item

create table auction_house.auction_item (
    auction_id int not null,
    item_id int not null,
    primary key (auction_id, item_id),  -- composite key for uniqueness
    foreign key (auction_id) references auction_house.auction(auction_id) on delete cascade,
    foreign key (item_id) references auction_house.item(item_id) on delete cascade
);

--creating table auction_history

create table auction_house.auction_history (
    history_id serial primary key,
    item_id int not null,
    auction_id int not null,
    previous_price decimal(10,2) not null check (previous_price > 0),
    sold_status boolean not null, -- indicates if item was sold
    history_date timestamp not null check (history_date > '2000-01-01 00:00:00'),
    foreign key (item_id) references auction_house.item(item_id) on delete cascade,
    foreign key (auction_id) references auction_house.auction(auction_id) on delete cascade
);

--creating table auction_employee

create table auction_house.auction_employee (
    employee_id serial primary key,
    name varchar(100) not null,
    auction_id int not null,
    role auction_house.employee_role not null,  -- uses ENUM to restrict to predefined roles
    contact_info varchar(255) not null,
    foreign key (auction_id) references auction_house.auction(auction_id) on delete cascade
);

--creating table auction_log

create table auction_house.auction_log (
    log_id serial primary key,
    item_id int not null,
    auction_id int not null,
    buyer_id int not null,
    auction_type varchar(50) not null,
    log_time timestamp not null check (log_time > '2000-01-01 00:00:00'),
    details text,
    foreign key (item_id) references auction_house.item(item_id) on delete cascade,
    foreign key (auction_id) references auction_house.auction(auction_id) on delete cascade,
    foreign key (buyer_id) references auction_house.buyer(buyer_id) on delete cascade
);

--creating table bid

create table auction_house.bid (
    bid_id serial primary key,
    auction_id int not null,
    item_id int not null,
    buyer_id int not null,
    bid_amount decimal(10,2) not null check (bid_amount > 0), -- currency-safe price field
    bid_time timestamp not null check (bid_time > '2000-01-01 00:00:00'),
    foreign key (auction_id) references auction_house.auction(auction_id) on delete cascade,
    foreign key (item_id) references auction_house.item(item_id) on delete cascade,
    foreign key (buyer_id) references auction_house.buyer(buyer_id) on delete cascade
);

--creating table purchase

create table auction_house.purchase (
    purchase_id serial primary key,
    auction_id int not null,
    item_id int not null,
    buyer_id int not null,
    final_price decimal(10,2) not null check (final_price > 0),
    purchase_date timestamp not null check (purchase_date > '2000-01-01 00:00:00'),
    foreign key (auction_id) references auction_house.auction(auction_id) on delete cascade,
    foreign key (item_id) references auction_house.item(item_id) on delete cascade,
    foreign key (buyer_id) references auction_house.buyer(buyer_id) on delete cascade
);

--creating table payment

create table auction_house.payment (
    payment_id serial primary key,
    purchase_id int not null,
    payment_method varchar(50) not null,
    payment_status varchar(50) not null,
    amount decimal(10,2) not null check (amount > 0),
    payment_date timestamp not null check (payment_date > '2000-01-01 00:00:00'),
    foreign key (purchase_id) references auction_house.purchase(purchase_id) on delete cascade
);

--creating table shipment

create table auction_house.shipment (
    shipment_id serial primary key,
    purchase_id int not null,
    shipment_address varchar(255) not null,
    carrier varchar(100) not null,
    tracking_number varchar(255) unique,
    status varchar(50) not null,
    estimated_date timestamp not null check (estimated_date > '2000-01-01 00:00:00'),
    foreign key (purchase_id) references auction_house.purchase(purchase_id) on delete cascade
);

-- if not exists
insert into auction_house.auction (date_time, location)
select '2025-04-10 10:00:00', 'Belgrade'
where not exists (
    select 1 from auction_house.auction where date_time = '2025-07-01 10:00:00' and location = 'beograd'
);
