
-- create
CREATE TABLE TAUser (
  user_id INTEGER PRIMARY KEY,
  user_name VARCHAR(20) NOT NULL,
  password VARCHAR(20) NOT NULL,
  phone VARCHAR(14) NOT NULL,
  email VARCHAR(40) NOT NULL
);

CREATE TABLE Restaurant (
  restaurant_id INTEGER PRIMARY KEY,
  address VARCHAR(40) NOT NULL,
  phone VARCHAR(14) NOT NULL,
  email VARCHAR(40) NOT NULL
);

CREATE TABLE Menu (
  menu_id INTEGER PRIMARY KEY,
  date_added DATE,
  restaurant_id INTEGER NOT NULL,
  foreign KEY(restaurant_id) references Restaurant(restaurant_id)
);

CREATE TABLE Item (
  item_id INTEGER PRIMARY KEY,
  price decimal NOT NULL,
  type VARCHAR(20) NOT NULL
 
);

CREATE TABLE Payment (
  payment_id INTEGER PRIMARY KEY,
  type VARCHAR(20) NOT NULL,
  status VARCHAR(20) NOT NULL check(status in('pending', 'completed', 'failed', 'refunded'))
);

CREATE TABLE FoodOrder (
  order_id INTEGER PRIMARY KEY,  
  payment_id INTEGER NOT NULL,
  date DATE,
  user_id INTEGER NOT NULL,
  arrival_address VARCHAR(40) NOT NULL,
  comment_to_restaurant TEXT,
  time_made TIME,
  time_closed TIME default null,
  check(time_closed IS NULL OR time_closed > time_made),
  foreign KEY(user_id) references TAUser(user_id),
  foreign KEY(payment_id) references Payment(payment_id)
);

CREATE TABLE Courier (
  courrier_id INTEGER PRIMARY KEY,
  name VARCHAR(20) NOT NULL,
  
);

CREATE TABLE Delivery (
  delivery_id INTEGER PRIMARY KEY,
  courrier_id INTEGER,
  type VARCHAR(20) NOT NULL check(type in('delivery', 'pick up')),
  expected_time time,
  status VARCHAR(20)  NOT NULL check(status in('delivered', 'being made', 'on way')),
  order_id INTEGER NOT NULL,
  foreign KEY(courrier_id) references Courier(courrier_id),
  foreign KEY(order_id) references FoodOrder(order_id)
);

CREATE TABLE Compound_Item (
  parent_item_id INTEGER,
  child_item_id INTEGER,
  PRIMARY KEY (parent_item_id, child_item_id),
  foreign KEY(parent_item_id) references Item(item_id),
  foreign KEY(child_item_id) references Item(item_id),
);

CREATE TABLE Item_Menu (
  item_id INTEGER,
  menu_id INTEGER,
  PRIMARY KEY(item_id, menu_id),
  foreign KEY(item_id) references Item(item_id),
  foreign key(menu_id) references Menu(menu_id)
);

CREATE TABLE Item_Order (
  item_id INTEGER,
  order_id INTEGER,
  PRIMARY KEY(item_id, order_id),
  foreign KEY(item_id) references Item(item_id),
  foreign key(order_id) references FoodOrder(order_id)
);

Create TABLE Review(
	user_id INTEGER,
	restaurant_id INTEGER,
	score INTEGER NOT NULL check(score <6 and score>0),
	comment TEXT,
	PRIMARY KEY (user_id, restaurant_id),
	foreign KEY(user_id) references TAUser(user_id),
	foreign KEY(restaurant_id) references Restaurant(restaurant_id)
);

