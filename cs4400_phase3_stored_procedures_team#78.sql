-- CS4400: Introduction to Database Systems (Fall 2022)
-- Project Phase III: Stored Procedures SHELL [v0] Monday, Oct 31, 2022
set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;

use restaurant_supply_express;
-- -----------------------------------------------------------------------------
-- stored procedures and views
-- -----------------------------------------------------------------------------
/* Standard Procedure: If one or more of the necessary conditions for a procedure to
be executed is false, then simply have the procedure halt execution without changing
the database state. Do NOT display any error messages, etc. */

-- [1] add_owner()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new owner.  A new owner must have a unique
username.  Also, the new owner is not allowed to be an employee. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_owner;
delimiter //
create procedure add_owner (in ip_username varchar(40), in ip_first_name varchar(100),
	in ip_last_name varchar(100), in ip_address varchar(500), in ip_birthdate date)
sp_main: begin
    -- ensure new owner has a unique username
    if ip_username in (select username from users)
    then leave sp_main; end if;
    insert into users values (ip_username, ip_first_name, ip_last_name, ip_address, ip_birthdate);
    insert into restaurant_owners values (ip_username);
end //
delimiter ;

-- [2] add_employee()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new employee without any designated pilot or
worker roles.  A new employee must have a unique username unique tax identifier. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_employee;
delimiter //
create procedure add_employee (in ip_username varchar(40), in ip_first_name varchar(100),
	in ip_last_name varchar(100), in ip_address varchar(500), in ip_birthdate date,
    in ip_taxID varchar(40), in ip_hired date, in ip_employee_experience integer,
    in ip_salary integer)
sp_main: begin
    -- ensure new owner has a unique username
    -- ensure new employee has a unique tax identifier
    
    if ip_username in (select username from users) 
    then leave sp_main; end if;
    if ip_taxID in (select taxID from employees)
    then leave sp_main; end if;
     
    insert into users values (ip_username, ip_first_name, ip_last_name, ip_address, ip_birthdate);
    insert into employees values (ip_username, ip_taxID, ip_hired, ip_employee_experience, ip_salary);
end //
delimiter ;

-- [3] add_pilot_role()
-- -----------------------------------------------------------------------------
/* This stored procedure adds the pilot role to an existing employee.  The
employee/new pilot must have a unique license identifier. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_pilot_role;
delimiter //
create procedure add_pilot_role (in ip_username varchar(40), in ip_licenseID varchar(40),
	in ip_pilot_experience integer)
sp_main: begin
    -- ensure new employee exists
    -- ensure new pilot has a unique license identifier
    
    if ip_username not in (select username from employees)
    then leave sp_main; end if;
    if ip_username in (select username from pilots)
    then leave sp_main; end if;
    if ip_licenseID in (select licenseID from pilots)
    then leave sp_main; end if;
	
    insert into pilots values (ip_username, ip_licenseID, ip_pilot_experience);
end //
delimiter ;


-- [4] add_worker_role()
-- -----------------------------------------------------------------------------
/* This stored procedure adds the worker role to an existing employee. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_worker_role;
delimiter //
create procedure add_worker_role (in ip_username varchar(40))
sp_main: begin
    -- ensure new employee exists
    if ip_username not in (select username from employees)
	then leave sp_main; end if;
	if ip_username in (select username from workers)
    then leave sp_main; end if;
    insert workers values (ip_username);
end //
delimiter ;


-- [5] add_ingredient()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new ingredient.  A new ingredient must have a
unique barcode. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_ingredient;
delimiter //
create procedure add_ingredient (in ip_barcode varchar(40), in ip_iname varchar(100),
	in ip_weight integer)
sp_main: begin
	-- ensure new ingredient doesn't already exist
    if ip_barcode in (select barcode from ingredients)
	then leave sp_main; end if;
	insert into ingredients values (ip_barcode, ip_iname, ip_weight);
end //
delimiter ;

-- [6] add_drone()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new drone.  A new drone must be assigned 
to a valid delivery service and must have a unique tag.  Also, it must be flown
by a valid pilot initially (i.e., pilot works for the same service), but the pilot
can switch the drone to working as part of a swarm later. And the drone's starting
location will always be the delivery service's home base by default. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_drone;
delimiter //
create procedure add_drone (in ip_id varchar(40), in ip_tag integer, in ip_fuel integer,
	in ip_capacity integer, in ip_sales integer, in ip_flown_by varchar(40))
sp_main: begin
	-- ensure new drone doesn't already exist
    -- ensure that the delivery service exists
    -- ensure that a valid pilot will control the drone
    if (ip_id, ip_tag) in (select id, tag from drones)
    then leave sp_main; end if;
    if ip_id not in (select id from delivery_services)
    then leave sp_main; end if;
    if (ip_id not in (select id from work_for where username = ip_flown_by))
    then leave sp_main; end if;
	set @deflocation = (select home_base from delivery_services where id = ip_id);
    INSERT INTO drones VALUES (ip_id, ip_tag, ip_fuel, ip_capacity, ip_sales, ip_flown_by, NULL, NULL, @deflocation);
end //
delimiter ;

-- [7] add_restaurant()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new restaurant.  A new restaurant must have a
unique (long) name and must exist at a valid location, and have a valid rating.
And a resturant is initially "independent" (i.e., no owner), but will be assigned
an owner later for funding purposes. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_restaurant;
delimiter //
create procedure add_restaurant (in ip_long_name varchar(40), in ip_rating integer,
	in ip_spent integer, in ip_location varchar(40))
sp_main: begin
	-- ensure new restaurant doesn't already exist
    -- ensure that the location is valid
    -- ensure that the rating is valid (i.e., between 1 and 5 inclusively)
    if ip_long_name in (select long_name from restaurants)
    then leave sp_main; end if;
    if ip_location not in (select label from locations)
    then leave sp_main; end if;
    if ip_rating NOT BETWEEN 1 AND 5
    then leave sp_main; end if;
    INSERT INTO restaurants VALUES (ip_long_name, ip_rating, ip_spent, ip_location, NULL);
end //
delimiter ;

-- [8] add_service()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new delivery service.  A new service must have
a unique identifier, along with a valid home base and manager. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_service;
delimiter //
create procedure add_service (in ip_id varchar(40), in ip_long_name varchar(100),
 in ip_home_base varchar(40), in ip_manager varchar(40))
sp_main: begin
 -- ensure new delivery service doesn't already exist
    -- ensure that the home base location is valid
    -- ensure that the manager is valid
    if ip_id in (select id from delivery_services)
    then leave sp_main; end if;
    if ip_home_base not in (select label from locations)
    then leave sp_main; end if;
    if ip_manager not in (select username from workers)
    then leave sp_main; end if;
    if ip_manager in (select manager from delivery_services)
    then leave sp_main; end if;
    
    insert into delivery_services values (ip_id, ip_long_name, ip_home_base, ip_manager);
end //
delimiter ;

-- [9] add_location()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new location that becomes a new valid drone
destination.  A new location must have a unique combination of coordinates.  We
could allow for "aliased locations", but this might cause more confusion that
it's worth for our relatively simple system. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_location;
delimiter //
create procedure add_location (in ip_label varchar(40), in ip_x_coord integer,
 in ip_y_coord integer, in ip_space integer)
sp_main: begin
 -- ensure new location doesn't already exist
    -- ensure that the coordinate combination is distinct
    if ip_label in (select label from locations)
    then leave sp_main; end if;
    if (select count(*) from locations where x_coord = ip_x_coord and y_coord = ip_y_coord) >=1
    then leave sp_main; end if;
    insert into locations values (ip_label, ip_x_coord, ip_y_coord, ip_space);
end //
delimiter ;

-- [10] start_funding()
-- -----------------------------------------------------------------------------
/* This stored procedure opens a channel for a restaurant owner to provide funds
to a restaurant. If a different owner is already providing funds, then the current
owner is replaced with the new owner.  The owner and restaurant must be valid. */
-- -----------------------------------------------------------------------------
drop procedure if exists start_funding;
delimiter //
create procedure start_funding (in ip_owner varchar(40), in ip_long_name varchar(40))
sp_main: begin
	-- ensure the owner and restaurant are valid
    if ip_owner not in (select username from restaurant_owners)
    then leave sp_main; end if;
    -- if (select count(*) from restaurant_owners where username = ip_owner) = 0
    -- if (select count(*) from restaurants where long_name = ip_long_name) = 0
    if ip_long_name not in (select long_name from restaurants)
    then leave sp_main; end if;
    update restaurants set funded_by = ip_owner 
    where long_name = ip_long_name;
end //
delimiter ;

-- [11] hire_employee()
-- -----------------------------------------------------------------------------
/* This stored procedure hires an employee to work for a delivery service.
Employees can be combinations of workers and pilots. If an employee is actively
controlling drones or serving as manager for a different service, then they are
not eligible to be hired.  Otherwise, the hiring is permitted. */
-- -----------------------------------------------------------------------------
drop procedure if exists hire_employee;
delimiter //
create procedure hire_employee (in ip_username varchar(40), in ip_id varchar(40))
sp_main: begin
	-- ensure that the employee hasn't already been hired
	-- ensure that the employee and delivery service are valid
    -- ensure that the employee isn't a manager for another service
	-- ensure that the employee isn't actively controlling drones for another service
    if (ip_username, ip_id) in (select username, id from work_for)
    then leave sp_main; end if;
    if ip_username not in (select username from employees)
    then leave sp_main; end if;
    if ip_id not in (select id from delivery_services)
    then leave sp_main; end if;
    if ip_username in (select manager from delivery_services)
    then leave sp_main; end if;
    if ip_username in (select flown_by from drones)
    then leave sp_main; end if;
    
    insert into work_for values (ip_username, ip_id);
end //
delimiter ;

-- [12] fire_employee()
-- -----------------------------------------------------------------------------
/* This stored procedure fires an employee who is currently working for a delivery
service.  The only restrictions are that the employee must not be: [1] actively
controlling one or more drones; or, [2] serving as a manager for the service.
Otherwise, the firing is permitted. */
-- -----------------------------------------------------------------------------
drop procedure if exists fire_employee;
delimiter //
create procedure fire_employee (in ip_username varchar(40), in ip_id varchar(40))
sp_main: begin
	-- ensure that the employee is currently working for the service
    -- ensure that the employee isn't an active manager
	-- ensure that the employee isn't controlling any drones
    
    if ip_username not in (select username from work_for)
    then leave sp_main; end if;
    if ip_username in (select manager from delivery_services)
    then leave sp_main; end if;
    if ip_username in (select flown_by from drones)
    then leave sp_main; end if;
    
    delete from work_for where ip_username = username;
end //
delimiter ;


-- [13] manage_service()
-- -----------------------------------------------------------------------------
/* This stored procedure appoints an employee who is currently hired by a delivery
service as the new manager for that service.  The only restrictions are that: [1]
the employee must not be working for any other delivery service; and, [2] the
employee can't be flying drones at the time.  Otherwise, the appointment to manager
is permitted.  The current manager is simply replaced.  And the employee must be
granted the worker role if they don't have it already. */
-- -----------------------------------------------------------------------------
drop procedure if exists manage_service;
delimiter //
create procedure manage_service (in ip_username varchar(40), in ip_id varchar(40))
sp_main: begin
	-- ensure that the employee is currently working for the service
	-- ensure that the employee is not flying any drones
    -- ensure that the employee isn't working for any other services
    -- add the worker role if necessary
    if ip_username not in (select username from work_for where id = ip_id)
    then leave sp_main; end if;
    if ip_username in (select username from pilots where username = ip_username)
    then leave sp_main; end if;
    if (select count(*) from work_for where username = ip_username) > 1
    then leave sp_main; end if;
    if ip_username not in (select username from workers)
    then insert into workers values (ip_username); end if;
    update delivery_services set manager = ip_username
    where id = ip_id;
end //
delimiter ;

-- [14] takeover_drone()
-- -----------------------------------------------------------------------------
/* This stored procedure allows a valid pilot to take control of a lead drone owned
by the same delivery service, whether it's a "lone drone" or the leader of a swarm.
The current controller of the drone is simply relieved of those duties. And this
should only be executed if a "leader drone" is selected. */
-- -----------------------------------------------------------------------------
drop procedure if exists takeover_drone;
delimiter //
create procedure takeover_drone (in ip_username varchar(40), in ip_id varchar(40),
	in ip_tag integer)
sp_main: begin
	-- ensure that the employee is currently working for the service
	-- ensure that the selected drone is owned by the same service and is a leader and not follower
	-- ensure that the employee isn't a manager
    -- ensure that the employee is a valid pilot
    if ip_username not in (select username from work_for where id = ip_id)
    then leave sp_main; end if;
    if ip_tag not in (select tag from drones where id = ip_id)
    then leave sp_main; end if;
    if (ip_id, ip_tag) in (select id, tag from drones where swarm_id is not null)
    then leave sp_main; end if;
    if ip_username in (select manager from delivery_services)
    then leave sp_main; end if;
    if ip_username not in (select username from pilots)
    then leave sp_main; end if;
    update drones set flown_by = ip_username
    where id = ip_id and tag = ip_tag;
end //
delimiter ;

-- [15] join_swarm()
-- -----------------------------------------------------------------------------
/* This stored procedure takes a drone that is currently being directly controlled
by a pilot and has it join a swarm (i.e., group of drones) led by a different
directly controlled drone. A drone that is joining a swarm connot be leading a
different swarm at this time.  Also, the drones must be at the same location, but
they can be controlled by different pilots. */
-- -----------------------------------------------------------------------------
drop procedure if exists join_swarm;
delimiter //
create procedure join_swarm (in ip_id varchar(40), in ip_tag integer,
	in ip_swarm_leader_tag integer)
sp_main: begin
	-- ensure that the swarm leader is a different drone
	-- ensure that the drone joining the swarm is valid and owned by the service
    -- ensure that the drone joining the swarm is not already leading a swarm
	-- ensure that the swarm leader drone is directly controlled
	-- ensure that the drones are at the same location
    if ip_tag = ip_swarm_leader_tag
    then leave sp_main; end if;
    if ip_tag not in (select tag from drones where id = ip_id)
    then leave sp_main; end if;
    -- ensure the leader drone is in the service
    if ip_swarm_leader_tag not in (select tag from drones where id = ip_id)
    then leave sp_main; end if;
    if ip_tag in (select swarm_tag from drones where swarm_id = ip_id)
    then leave sp_main; end if;
    if (ip_id, ip_swarm_leader_tag) in (select id, tag from drones where flown_by is null)
    then leave sp_main; end if;
    if (select hover from drones where id = ip_id and tag = ip_tag) not in 
    (select hover from drones where id = ip_id and tag = ip_swarm_leader_tag)
    then leave sp_main; end if;
    update drones set swarm_id = ip_id, swarm_tag = ip_swarm_leader_tag, flown_by = null
    where id = ip_id and tag = ip_tag;
end //
delimiter ;

-- [16] leave_swarm()
-- -----------------------------------------------------------------------------
/* This stored procedure takes a drone that is currently in a swarm and returns
it to being directly controlled by the same pilot who's controlling the swarm. */
-- -----------------------------------------------------------------------------
drop procedure if exists leave_swarm;
delimiter //
create procedure leave_swarm (in ip_id varchar(40), in ip_swarm_tag integer)
sp_main: begin
	-- ensure that the selected drone is owned by the service and flying in a swarm
    if ip_swarm_tag not in (select tag from drones where id = ip_id)
    then leave sp_main; end if;
    if (ip_id, ip_swarm_tag) in (select id, tag from drones where swarm_id is null)
    then leave sp_main; end if;
    set @leadpilot = (select flown_by from drones where id = ip_id and tag = (select swarm_tag from drones where id = ip_id and tag = ip_swarm_tag));
    update drones set swarm_id = null, swarm_tag = null, flown_by = @leadpilot
    where id = ip_id and tag = ip_swarm_tag;
end //
delimiter ;

-- [17] load_drone()
-- -----------------------------------------------------------------------------
/* This stored procedure allows us to add some quantity of fixed-size packages of
a specific ingredient to a drone's payload so that we can sell them for some
specific price to other restaurants.  The drone can only be loaded if it's located
at its delivery service's home base, and the drone must have enough capacity to
carry the increased number of items.

The change/delta quantity value must be positive, and must be added to the quantity
of the ingredient already loaded onto the drone as applicable.  And if the ingredient
already exists on the drone, then the existing price must not be changed. */
-- -----------------------------------------------------------------------------
drop procedure if exists load_drone;
delimiter //
create procedure load_drone (in ip_id varchar(40), in ip_tag integer, in ip_barcode varchar(40),
	in ip_more_packages integer, in ip_price integer)
sp_main: begin
	-- ensure that the drone being loaded is owned by the service
	-- ensure that the ingredient is valid
    -- ensure that the drone is located at the service home base
	-- ensure that the quantity of new packages is greater than zero
	-- ensure that the drone has sufficient capacity to carry the new packages
    -- add more of the ingredient to the drone
    if ip_tag not in (select tag from drones where id = ip_id)
    then leave sp_main; end if;
    if ip_barcode not in (select barcode from ingredients)
    then leave sp_main; end if;
    set @curlocation = (select hover from drones where (id, tag) = (ip_id, ip_tag));
    set @rmncapacity = (select (select capacity from drones where (id, tag) = (ip_id, ip_tag)) - (select sum(quantity) from payload where (id, tag) = (ip_id, ip_tag)));
    if @curlocation not in (select home_base from delivery_services where id = ip_id)
    then leave sp_main; end if;
    if ip_more_packages <= 0
    then leave sp_main; end if;
    if ip_more_packages > @rmncapacity
    then leave sp_main; end if;
    if ((select count(*) from payload where id = ip_id and tag = ip_tag and barcode = ip_barcode) > 0)
    then update payload set quantity = (quantity + ip_more_packages) where id = ip_id and tag = ip_tag and barcode = ip_barcode;
    else insert payload values (ip_id, ip_tag, ip_barcode, ip_more_packages, ip_price); end if;
end //
delimiter ;

-- [18] refuel_drone()
-- -----------------------------------------------------------------------------
/* This stored procedure allows us to add more fuel to a drone. The drone can only
be refueled if it's located at the delivery service's home base. */
-- -----------------------------------------------------------------------------
drop procedure if exists refuel_drone;
delimiter //
create procedure refuel_drone (in ip_id varchar(40), in ip_tag integer, in ip_more_fuel integer)
sp_main: begin
	-- ensure that the drone being switched is valid and owned by the service
    -- ensure that the drone is located at the service home base
    if ip_tag not in (select tag from drones where id = ip_id)
    then leave sp_main; end if;
    set @curlocation = (select hover from drones where (id, tag) = (ip_id, ip_tag));
	if @curlocation not in (select home_base from delivery_services where id = ip_id)
    then leave sp_main; end if;
    update drones set fuel = fuel + ip_more_fuel where (id, tag) = (ip_id, ip_tag);
end //
delimiter ;

-- [19] fly_drone()
-- -----------------------------------------------------------------------------
/* This stored procedure allows us to move a single or swarm of drones to a new
location (i.e., destination). The main constraints on the drone(s) being able to
move to a new location are fuel and space.  A drone can only move to a destination
if it has enough fuel to reach the destination and still move from the destination
back to home base.  And a drone can only move to a destination if there's enough
space remaining at the destination.  For swarms, the flight directions will always
be given to the lead drone, but the swarm must always stay together. */
-- -----------------------------------------------------------------------------
drop function if exists fuel_required;
delimiter //
create function fuel_required (ip_departure varchar(40), ip_arrival varchar(40))
	returns integer reads sql data
begin
	if (ip_departure = ip_arrival) then return 0;
    else return (select 1 + truncate(sqrt(power(arrival.x_coord - departure.x_coord, 2) + power(arrival.y_coord - departure.y_coord, 2)), 0) as fuel
		from (select x_coord, y_coord from locations where label = ip_departure) as departure,
        (select x_coord, y_coord from locations where label = ip_arrival) as arrival);
	end if;
end //
delimiter ;

drop procedure if exists fly_drone;
delimiter //
create procedure fly_drone (in ip_id varchar(40), in ip_tag integer, in ip_destination varchar(40))
sp_main: begin
	-- ensure that the lead drone being flown is directly controlled and owned by the service
    -- ensure that the destination is a valid location
    -- ensure that the drone isn't already at the location
    -- ensure that the drone/swarm has enough fuel to reach the destination and (then) home base
    -- ensure that the drone/swarm has enough space at the destination for the flight
    if ip_tag not in (select tag from drones where id = ip_id and flown_by is not null)
    then leave sp_main; end if;
    if ip_destination not in (select label from locations)
    then leave sp_main; end if;
    if ip_destination in (select hover from drones where id = ip_id and tag = ip_tag)
    then leave sp_main; end if;
    set @departure = (select hover from drones where id = ip_id and tag = ip_tag);
    if (select min(fuel) from drones where (id = ip_id and tag = ip_tag) or (swarm_id = ip_id and swarm_tag = ip_tag)) <=
    2 * (select fuel_required(@departure, ip_destination))
	then leave sp_main; end if;
    if (select (count(*)+1) from drones where swarm_id = ip_id and swarm_tag = ip_tag) > 
    (select space from locations where label = ip_destination)
    then leave sp_main; end if;
    
    update drones set hover  = ip_destination
    where id = ip_id and tag = ip_tag;
    update drones set hover  = ip_destination
    where swarm_id = ip_id and swarm_tag = ip_tag;
    update drones set fuel = fuel - (select fuel_required(@departure, ip_destination))
    where id = ip_id and tag = ip_tag;
    update drones set fuel = fuel - (select fuel_required(@departure, ip_destination))
	where swarm_id = ip_id and swarm_tag = ip_tag;
end //
delimiter ;

-- [20] purchase_ingredient()
-- -----------------------------------------------------------------------------
/* This stored procedure allows a restaurant to purchase ingredients from a drone
at its current location.  The drone must have the desired quantity of the ingredient
being purchased.  And the restaurant must have enough money to purchase the
ingredients.  If the transaction is otherwise valid, then the drone and restaurant
information must be changed appropriately.  Finally, we need to ensure that all
quantities in the payload table (post transaction) are greater than zero. */
-- -----------------------------------------------------------------------------
drop procedure if exists purchase_ingredient;
delimiter //
create procedure purchase_ingredient (in ip_long_name varchar(40), in ip_id varchar(40),
	in ip_tag integer, in ip_barcode varchar(40), in ip_quantity integer)
sp_main: begin
	-- ensure that the restaurant is valid
    -- ensure that the drone is valid and exists at the resturant's location
	-- ensure that the drone has enough of the requested ingredient
	-- update the drone's payload
    -- update the monies spent and gained for the drone and restaurant
    -- ensure all quantities in the payload table are greater than zero
    if ip_long_name not in (select long_name from restaurants)
    then leave sp_main; end if;
    if (ip_id, ip_tag) not in (select id, tag from drones where hover = (select location from restaurants where long_name = ip_long_name))
    then leave sp_main; end if;
    if ip_quantity > any (select quantity from payload where id = ip_id and tag = ip_tag and barcode = ip_barcode)
    then leave sp_main; end if;
    update payload set quantity = quantity - ip_quantity
    where id = ip_id and tag = ip_tag and barcode = ip_barcode;
    set @monies = ip_quantity * (select price from payload where id = ip_id and tag = ip_tag and barcode = ip_barcode);
    update drones set sales = sales + @monies
    where id = ip_id and tag = ip_tag;
    update restaurants set spent = spent + @monies
    where long_name = ip_long_name;
end //
delimiter ;

-- [21] remove_ingredient()
-- -----------------------------------------------------------------------------
/* This stored procedure removes an ingredient from the system.  The removal can
occur if, and only if, the ingredient is not being carried by any drones. */
-- -----------------------------------------------------------------------------
drop procedure if exists remove_ingredient;
delimiter //
create procedure remove_ingredient (in ip_barcode varchar(40))
sp_main: begin
	-- ensure that the ingredient exists
    -- ensure that the ingredient is not being carried by any drones
    if ip_barcode not in (select barcode from ingredients)
    or ip_barcode in (select barcode from payload)
    then leave sp_main; end if;
    delete from ingredients where barcode = ip_barcode;
end //
delimiter ;

-- [22] remove_drone()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a drone from the system.  The removal can
occur if, and only if, the drone is not carrying any ingredients, and if it is
not leading a swarm. */
-- -----------------------------------------------------------------------------
drop procedure if exists remove_drone;
delimiter //
create procedure remove_drone (in ip_id varchar(40), in ip_tag integer)
sp_main: begin
	-- ensure that the drone exists
    -- ensure that the drone is not carrying any ingredients
	-- ensure that the drone is not leading a swarm
    if (ip_id, ip_tag) not in (select id, tag from drones)
    then leave sp_main; end if;
    if (ip_id, ip_tag) in (select id, tag from payload)
    then leave sp_main; end if;
    if (ip_id, ip_tag) in (select swarm_id, swarm_tag from drones where swarm_id is not NULL)
    then leave sp_main; end if;
    delete from drones where (id, tag) = (ip_id, ip_tag);
end //
delimiter ;

-- [23] remove_pilot_role()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a pilot from the system.  The removal can
occur if, and only if, the pilot is not controlling any drones.  Also, if the
pilot also has a worker role, then the worker information must be maintained;
otherwise, the pilot's information must be completely removed from the system. */
-- -----------------------------------------------------------------------------
drop procedure if exists remove_pilot_role;
delimiter //
create procedure remove_pilot_role (in ip_username varchar(40))
sp_main: begin
 -- ensure that the pilot exists
    -- ensure that the pilot is not controlling any drones
    -- remove all remaining information unless the pilot is also a worker
   
   if ip_username not in (select username from pilots)
   then leave sp_main; end if;
   if ip_username in (select flown_by from drones)
   then leave sp_main; end if;
   if ip_username in (select username from workers) 
   then leave sp_main; end if;
   
   delete from work_for where ip_username = username;
   delete from users where ip_username = username;
end //
delimiter ;

-- [24] display_owner_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of an owner.
For each owner, it includes the owner's information, along with the number of
restaurants for which they provide funds and the number of different places where
those restaurants are located.  It also includes the highest and lowest ratings
for each of those restaurants, as well as the total amount of debt based on the
monies spent purchasing ingredients by all of those restaurants. And if an owner
doesn't fund any restaurants then display zeros for the highs, lows and debt. */
-- -----------------------------------------------------------------------------
create or replace view display_owner_view as
select 
	restaurant_owners.username, 
    first_name, 
    last_name, 
    address, 
    count(long_name) as num_restaurants, 
    count(distinct location) as num_places, 
    ifnull(max(rating), 0) as highs, 
    ifnull(min(rating), 0) as lows, 
    ifnull(sum(spent), 0) as debt
from (users inner join restaurant_owners on users.username = restaurant_owners.username) left outer join restaurants
on restaurant_owners.username = funded_by
group by username;

-- [25] display_employee_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of an employee.
For each employee, it includes the username, tax identifier, hiring date and
experience level, along with the license identifer and piloting experience (if
applicable), and a 'yes' or 'no' depending on the manager status of the employee. */
-- -----------------------------------------------------------------------------
drop function if exists manager_status;
DELIMITER //

create function manager_status(ip_username varchar(40), ip_manager varchar(40))
  returns varchar(20) reads sql data

  begin
    declare s varchar(20);

    if ip_username = ip_manager then set s = 'yes';
    else set s = 'no';
    end if;

    return s;
  end //

DELIMITER ;

create or replace view display_employee_view as
select distinct
	employees.username, 
    taxID, 
    salary, 
    hired, 
    employees.experience as employee_experience, 
    ifnull(licenseID, 'n/a') as licenseID, 
    ifnull(pilots.experience, 'n/a') as piloting_experience,
    manager_status(employees.username, delivery_services.manager) as manager_status
from (employees left outer join pilots on employees.username = pilots.username) left outer join delivery_services
on employees.username = delivery_services.manager;

-- [26] display_pilot_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of a pilot.
For each pilot, it includes the username, licenseID and piloting experience, along
with the number of drones that they are controlling. */
-- -----------------------------------------------------------------------------
create or replace view display_pilot_view as
select
	username,
    licenseID,
    experience,
    count(distinct d1.id, d1.tag) + count(distinct d2.id, d2.tag) as num_drones,
    count(distinct d1.hover) as num_locations
from pilots left outer join 
(drones as d1 left outer join drones as d2 on (d1.id, d1.tag) = (d2.swarm_id, d2.swarm_tag))
on username = d1.flown_by
group by username;

-- [27] display_location_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of a location.
For each location, it includes the label, x- and y- coordinates, along with the
number of restaurants, delivery services and drones at that location. */
-- -----------------------------------------------------------------------------
create or replace view display_location_view as
select
	label,
    x_coord,
    y_coord,
    count(distinct restaurants.long_name) as num_restaurants,
    count(distinct delivery_services.id) as num_delivery_services,
    count(distinct drones.id, drones.tag) as num_drones
from ((locations left outer join restaurants on label = location) 
left outer join delivery_services on label = home_base) left outer join drones
on label = hover
group by label;

-- [28] display_ingredient_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of the ingredients.
For each ingredient that is being carried by at least one drone, it includes a list of
the various locations where it can be purchased, along with the total number of packages
that can be purchased and the lowest and highest prices at which the ingredient is being
sold at that location. */
-- -----------------------------------------------------------------------------
create or replace view display_ingredient_view as
select
	iname as ingredient_name,
    hover as location,
    sum(quantity) as amount_available,
    min(price) as low_price,
    max(price) as high_price
from (payload inner join ingredients on ingredients.barcode = payload.barcode)
inner join drones
on (drones.id, drones.tag) = (payload.id, payload.tag)
group by ingredient_name, location;

-- [29] display_service_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of a delivery
service.  It includes the identifier, name, home base location and manager for the
service, along with the total sales from the drones.  It must also include the number
of unique ingredients along with the total cost and weight of those ingredients being
carried by the drones. */
-- -----------------------------------------------------------------------------
drop function if exists cal_revenue;
DELIMITER //

create function cal_revenue(ip_id varchar(40))
  returns integer reads sql data

  begin
    declare x integer;

    set x = (select sum(sales) from drones where id = ip_id);

    return x;
  end //

DELIMITER ;

create or replace view display_service_view as
select distinct
	delivery_services.id,
    long_name,
    home_base,
    manager,
    cal_revenue(delivery_services.id) as revenue,
    count(distinct payload.barcode) as ingredients_carried,
    sum(price * quantity) as cost_carried,
    sum(quantity * weight) as weight_carried
from (drones 
left outer join (payload left outer join ingredients on ingredients.barcode = payload.barcode)
on (drones.id, drones.tag) = (payload.id, payload.tag))
right outer join delivery_services on delivery_services.id = drones.id
group by id;