--An Auction House 
--creating table auction
-- i didn't change logical model so i didn't add it in git
create table auction (
    auctionid   serial primary key,
    datetime    timestamp not null 
                   check (datetime > '2000-01-01 00:00:00'),
    location    varchar(255) not null
);

--creating table category
create table category (
    categoryid    serial primary key,
    categoryname  varchar(255) not null unique,
    description   text
);

--creating table seller
create table seller (
    sellerid             serial primary key,
    name                 varchar(255) not null,
    sellercontactinfo    varchar(255) not null
);

--creating table buyer
create table buyer (
    buyerid             serial primary key,
    name                varchar(255) not null,
    buyercontactinfo    varchar(255) not null
);

--creating table item
create table item (
    itemid         serial primary key,
    lotnumber      varchar(50) not null unique,
    description    text not null,
    startingprice  decimal(10,2) not null check (startingprice > 0),
    sellerid       int not null,
    categoryid     int,
    constraint fk_seller_item foreign key (sellerid) references seller(sellerid) on delete cascade, -- delete items if seller is removed
    constraint fk_category_item foreign key (categoryid) references category(categoryid) on delete set null -- retain item if category deleted
);

--creating table auction_item
create table auction_item (
    auctionid int not null,
    itemid    int not null,
    primary key (auctionid, itemid), -- composite key for uniqueness
    constraint fk_auction_ai foreign key (auctionid) references auction(auctionid) on delete cascade,
    constraint fk_item_ai foreign key (itemid) references item(itemid) on delete cascade
);

--creating table auction_history
create table auction_history (
    historyid      serial primary key,
    itemid         int not null,
    auctionid      int not null,
    previousprice  decimal(10,2) not null check (previousprice > 0),
    soldstatus     boolean not null,  -- indicates if item was sold
    historydate    timestamp not null check (historydate > '2000-01-01 00:00:00'),
    constraint fk_item_history foreign key (itemid) references item(itemid) on delete cascade,
    constraint fk_auction_history foreign key (auctionid) references auction(auctionid) on delete cascade
);

--creating table auction_employee
create table auction_employee (
    employeeid   serial primary key,
    name         varchar(100) not null,
    auctionid    int not null,
    role         employee_role not null, -- uses ENUM to restrict to predefined roles
    contactinfo  varchar(255) not null,
    constraint fk_auction_employee foreign key (auctionid) references auction(auctionid) on delete cascade
);

--creating table auction_log
create table auction_log (
    logid      serial primary key,
    itemid     int not null,
    auctionid  int not null,
    buyerid    int not null,
    auctiontype varchar(50) not null,
    logtime    timestamp not null check (logtime > '2000-01-01 00:00:00'),
    details    text,
    constraint fk_item_log foreign key (itemid) references item(itemid) on delete cascade,
    constraint fk_auction_log foreign key (auctionid) references auction(auctionid) on delete cascade,
    constraint fk_buyer_log foreign key (buyerid) references buyer(buyerid) on delete cascade
);

--creating table bid
create table bid (
    bidid      serial primary key,
    auctionid  int not null,
    itemid     int not null,
    buyerid    int not null,
    bidamount  decimal(10,2) not null check (bidamount > 0), -- currency-safe price field
    bidtime    timestamp not null check (bidtime > '2000-01-01 00:00:00'),
    constraint fk_auction_bid foreign key (auctionid) references auction(auctionid) on delete cascade,
    constraint fk_item_bid foreign key (itemid) references item(itemid) on delete cascade,
    constraint fk_buyer_bid foreign key (buyerid) references buyer(buyerid) on delete cascade
);

--creating table purchase
create table purchase (
    purchaseid    serial primary key,
    auctionid     int not null,
    itemid        int not null,
    buyerid       int not null,
    finalprice    decimal(10,2) not null check (finalprice > 0),
    purchasedate  timestamp not null check (purchasedate > '2000-01-01 00:00:00'),
    constraint fk_auction_purchase foreign key (auctionid) references auction(auctionid) on delete cascade,
    constraint fk_item_purchase foreign key (itemid) references item(itemid) on delete cascade,
    constraint fk_buyer_purchase foreign key (buyerid) references buyer(buyerid) on delete cascade
);

--creating table payment
create table payment (
    payment_id    serial primary key,
    purchaseid    int not null,
    paymentmethod varchar(50) not null,
    paymenttatus varchar(50) not null,
    amount        decimal(10,2) not null check (amount > 0),
    paymentdate   timestamp not null check (paymentdate > '2000-01-01 00:00:00'),
    constraint fk_purchase_payment foreign key (purchaseid) references purchase(purchaseid) on delete cascade
);

--creating table shipment
create table shipment (
    shipmentid       serial primary key,
    purchaseid       int not null,
    shipmentaddress  varchar(255) not null,
    carrier          varchar(100) not null,
    trackingnumber   varchar(255) unique,
    status           varchar(50) not null,
    estimateddate    timestamp not null check (estimateddate > '2000-01-01 00:00:00'),
    constraint fk_purchase_shipment foreign key (purchaseid) references purchase(purchaseid) on delete cascade
);

--inserting sample data into auction:
insert into auction (datetime, location) values
('2025-07-01 10:00:00', 'new york'),
('2025-08-15 14:30:00', 'los angeles');

--inserting sample data into category:
insert into category (categoryname, description) values
('art', 'paintings and sculptures'),
('collectibles', 'rare and unique collectible items');

--inserting sample data into seller:
insert into seller (name, sellercontactinfo) values
('tamara jovicic', 'tamarajovicic44@gmail.com'),
('tami paul', 'tami.paul@gmail.com');

--inserting sample data into buyer:
insert into buyer (name, buyercontactinfo) values
('bojana jovicic', 'bojanajovicic@gmail.com'),
('isidora djurovic', 'isidora.djurovic@gmail.com');

--inserting sample data into item:
insert into item (lotnumber, description, startingprice, sellerid, categoryid) values
('l001', 'vintage painting from the 19th century', 500.00, 1, 1),
('l002', 'rare coin collection', 250.00, 2, 2);

--inserting sample data into auction_item:
insert into auction_item (auctionid, itemid) values
(1, 1),
(2, 2);

--inserting sample data into auction_history:
insert into auction_history (itemid, auctionid, previousprice, soldstatus, historydate) values
(1, 1, 450.00, true, '2025-07-01 11:00:00'),
(2, 2, 200.00, false, '2025-08-15 15:00:00');

--inserting sample data into auction_employee:
insert into auction_employee (name, auctionid, role, contactinfo) values
('anna smith', 1, 'manager', 'annasmith1@gmail.com'),
('liam davis', 2, 'auctioneer', 'liam.davis@gmail.com');

--inserting sample data into auction_log:
insert into auction_log (itemid, auctionid, buyerid, auctiontype, logtime, details) values
(1, 1, 1, 'live', '2025-07-01 11:30:00', 'item sold to highest bidder'),
(2, 2, 2, 'online', '2025-08-15 15:30:00', 'bid received, awaiting confirmation');

--inserting sample data into bid:
insert into bid (auctionid, itemid, buyerid, bidamount, bidtime) values
(1, 1, 2, 550.00, '2025-07-01 11:15:00'),
(2, 2, 1, 300.00, '2025-08-15 15:10:00');

--inserting sample data into purchase:
insert into purchase (auctionid, itemid, buyerid, finalprice, purchasedate) values
(1, 1, 2, 550.00, '2025-07-01 12:00:00'),
(2, 2, 1, 300.00, '2025-08-15 16:00:00');

--inserting sample data into payment:
insert into payment (purchaseid, paymentmethod, paymenttatus, amount, paymentdate) values
(1, 'card', 'completed', 550.00, '2025-07-01 12:30:00'),
(2, 'cash', 'completed', 300.00, '2025-08-15 16:30:00');

--inserting sample data into shipment:
insert into shipment (purchaseid, shipmentaddress, carrier, trackingnumber, status, estimateddate) values
(1, '123 main st, new york, ny', 'ups', 'track123', 'shipped', '2025-07-05 00:00:00'),
(2, '456 elm st, los angeles, ca', 'fedex', 'track456', 'pending', '2025-08-20 00:00:00');

--altering table auction with record_ts:
alter table auction add column record_ts date default current_date not null;
update auction set record_ts = current_date where record_ts is null;

--altering table category with record_ts:
alter table category add column record_ts date default current_date not null;
update category set record_ts = current_date where record_ts is null;

--altering table seller with record_ts:
alter table seller add column record_ts date default current_date not null;
update seller set record_ts = current_date where record_ts is null;

--altering table buyer with record_ts:
alter table buyer add column record_ts date default current_date not null;
update buyer set record_ts = current_date where record_ts is null;

--altering table item with record_ts:
alter table item add column record_ts date default current_date not null;
update item set record_ts = current_date where record_ts is null;

--altering table auction_item with record_ts:
alter table auction_item add column record_ts date default current_date not null;
update auction_item set record_ts = current_date where record_ts is null;

--altering table auction_history with record_ts:
alter table auction_history add column record_ts date default current_date not null;
update auction_history set record_ts = current_date where record_ts is null;

--altering table auction_employee with record_ts:
alter table auction_employee add column record_ts date default current_date not null;
update auction_employee set record_ts = current_date where record_ts is null;

--altering table auction_log with record_ts:
alter table auction_log add column record_ts date default current_date not null;
update auction_log set record_ts = current_date where record_ts is null;

--altering table bid with record_ts:
alter table bid add column record_ts date default current_date not null;
update bid set record_ts = current_date where record_ts is null;

--altering table purchase with record_ts:
alter table purchase add column record_ts date default current_date not null;
update purchase set record_ts = current_date where record_ts is null;

--altering table payment with record_ts:
alter table payment add column record_ts date default current_date not null;
update payment set record_ts = current_date where record_ts is null;

--altering table shipment with record_ts:
alter table shipment add column record_ts date default current_date not null;
update shipment set record_ts = current_date where record_ts is null;