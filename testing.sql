insert into "Report" (reason, post_id, reporter_id) values ( 'nudes', 2, 1);

delete from "Group" where id = 1;

update "Comment" set "text" = 'check' where id = 1;

insert into "Message" (sender_id, receiver_id, content)  values (1, 1, 'new message arrived');


select find_active_users();

select get_posts_with_likes_count();

select get_messages_between_users(1, 2);

select get_user_posts(1);

select get_user_notifications(1);
