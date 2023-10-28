CREATE TABLE "User"
(
    "id"         SERIAL PRIMARY KEY,
    "username"   varchar,
    "email"      varchar,
    "password"   varchar,
    "created_at" timestamp,
    unique (username, email)
);

CREATE TABLE "Post"
(
    "id"         SERIAL PRIMARY KEY,
    "content"    text,
    "user_id"    int,
    "created_at" timestamp default current_timestamp,
    suspicious   bool default false
);

CREATE TABLE "Report"
(
    "id"          SERIAL primary key,
    "reason"      text,
    "post_id"     int,
    "reporter_id" int
);

CREATE OR REPLACE FUNCTION mark_post_as_suspicious()
    RETURNS TRIGGER AS
$$
BEGIN
    UPDATE "Post" SET "suspicious" = true WHERE "id" = NEW."post_id";
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_mark_post_as_suspicious
    AFTER INSERT
    ON "Report"
    FOR EACH ROW
EXECUTE FUNCTION mark_post_as_suspicious();

CREATE TABLE "Comment"
(
    "id"         SERIAL PRIMARY KEY,
    "text"       text,
    "user_id"    int,
    "post_id"    int,
    "created_at" timestamp default current_timestamp,
    "edited_at"  timestamp
);

CREATE OR REPLACE FUNCTION update_edited_at_column()
    RETURNS TRIGGER AS
$$
BEGIN
    NEW.edited_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_ab_changetimestamp
    BEFORE UPDATE
    ON "Comment"
    FOR EACH ROW
EXECUTE PROCEDURE
    update_edited_at_column();

CREATE TABLE "Like"
(
    "id"         SERIAL PRIMARY KEY,
    "user_id"    int,
    "post_id"    int,
    "created_at" timestamp default current_timestamp,
    unique (user_id, post_id)
);

CREATE TABLE "Friend"
(
    "id"       SERIAL PRIMARY KEY,
    "user_id1" int,
    "user_id2" int,
    unique (user_id1, user_id2)
);

CREATE TABLE "Notification"
(
    "id"         SERIAL PRIMARY KEY,
    "user_id"    int,
    "content"    text,
    "created_at" timestamp default current_timestamp
);

CREATE TABLE "Message"
(
    "id"          SERIAL PRIMARY KEY,
    "sender_id"   int,
    "receiver_id" int,
    "content"     text,
    "created_at"  timestamp default current_timestamp
);

CREATE OR REPLACE FUNCTION create_notification_after_message_insert()
    RETURNS TRIGGER AS
$$
BEGIN
    INSERT INTO "Notification" ("user_id", "content", "created_at")
    VALUES (NEW."receiver_id", NEW."content", NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_create_notification
    AFTER INSERT
    ON "Message"
    FOR EACH ROW
EXECUTE FUNCTION create_notification_after_message_insert();

CREATE TABLE "Group"
(
    "id"         SERIAL PRIMARY KEY,
    "name"       varchar,
    "created_at" timestamp,
    unique (name)
);

CREATE TABLE "GroupMember"
(
    "id"       SERIAL PRIMARY KEY,
    "group_id" int,
    "user_id"  int,
    unique (group_id, user_id)
);

CREATE OR REPLACE FUNCTION delete_group_members()
    RETURNS TRIGGER AS
$$
BEGIN
    DELETE FROM "GroupMember" WHERE "group_id" = OLD."id";
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_delete_group_members
    BEFORE DELETE
    ON "Group"
    FOR EACH ROW
EXECUTE FUNCTION delete_group_members();

CREATE TABLE "Event"
(
    "id"          SERIAL PRIMARY KEY,
    "title"       varchar,
    "description" text,
    "date"        timestamp default current_timestamp
);

CREATE TABLE "EventParticipant"
(
    "id"       SERIAL PRIMARY KEY,
    "event_id" int,
    "user_id"  int
);

CREATE TABLE "Photo"
(
    "id"         SERIAL PRIMARY KEY,
    "user_id"    int,
    "caption"    text,
    "created_at" timestamp default current_timestamp
);

CREATE TABLE "Tag"
(
    "id"   SERIAL PRIMARY KEY,
    "name" varchar
);

CREATE TABLE "PostTag"
(
    "post_id" int,
    "tag_id"  int
);

CREATE TABLE "Location"
(
    "id"   SERIAL PRIMARY KEY,
    "name" varchar
);

CREATE TABLE "Checkin"
(
    "id"           SERIAL PRIMARY KEY,
    "user_id"      int,
    "location_id"  int,
    "checkin_time" timestamp default current_timestamp
);

CREATE TABLE "Poll"
(
    "id"         SERIAL PRIMARY KEY,
    "question"   text,
    "user_id"    int,
    "created_at" timestamp
);

CREATE TABLE "PollOption"
(
    "id"          SERIAL PRIMARY KEY,
    "poll_id"     int,
    "option_text" varchar
);

ALTER TABLE "Post"
    ADD FOREIGN KEY ("user_id") REFERENCES "User" ("id");

ALTER TABLE "Comment"
    ADD FOREIGN KEY ("user_id") REFERENCES "User" ("id");

ALTER TABLE "Comment"
    ADD FOREIGN KEY ("post_id") REFERENCES "Post" ("id");

ALTER TABLE "Like"
    ADD FOREIGN KEY ("user_id") REFERENCES "User" ("id");

ALTER TABLE "Like"
    ADD FOREIGN KEY ("post_id") REFERENCES "Post" ("id");

ALTER TABLE "Friend"
    ADD FOREIGN KEY ("user_id1") REFERENCES "User" ("id");

ALTER TABLE "Friend"
    ADD FOREIGN KEY ("user_id2") REFERENCES "User" ("id");

ALTER TABLE "Notification"
    ADD FOREIGN KEY ("user_id") REFERENCES "User" ("id");

ALTER TABLE "Message"
    ADD FOREIGN KEY ("sender_id") REFERENCES "User" ("id");

ALTER TABLE "Message"
    ADD FOREIGN KEY ("receiver_id") REFERENCES "User" ("id");

ALTER TABLE "GroupMember"
    ADD FOREIGN KEY ("group_id") REFERENCES "Group" ("id");

ALTER TABLE "GroupMember"
    ADD FOREIGN KEY ("user_id") REFERENCES "User" ("id");

ALTER TABLE "EventParticipant"
    ADD FOREIGN KEY ("event_id") REFERENCES "Event" ("id");

ALTER TABLE "EventParticipant"
    ADD FOREIGN KEY ("user_id") REFERENCES "User" ("id");

ALTER TABLE "Photo"
    ADD FOREIGN KEY ("user_id") REFERENCES "User" ("id");

ALTER TABLE "PostTag"
    ADD FOREIGN KEY ("post_id") REFERENCES "Post" ("id");

ALTER TABLE "PostTag"
    ADD FOREIGN KEY ("tag_id") REFERENCES "Tag" ("id");

ALTER TABLE "Checkin"
    ADD FOREIGN KEY ("user_id") REFERENCES "User" ("id");

ALTER TABLE "Checkin"
    ADD FOREIGN KEY ("location_id") REFERENCES "Location" ("id");

ALTER TABLE "Poll"
    ADD FOREIGN KEY ("user_id") REFERENCES "User" ("id");

ALTER TABLE "PollOption"
    ADD FOREIGN KEY ("poll_id") REFERENCES "Poll" ("id");

ALTER TABLE "Report"
    ADD FOREIGN KEY ("post_id") REFERENCES "Post" ("id");

-- User functions

-- Get User's Posts

CREATE OR REPLACE FUNCTION get_user_posts(id_user int)
    RETURNS TABLE
            (
                content    text,
                created_at timestamp,
                suspicious bool
            )
AS
$$
BEGIN
    RETURN QUERY
        SELECT p.content, p.created_at, p.suspicious
        FROM "Post" p
        WHERE id_user = p.user_id;
END;
$$ LANGUAGE plpgsql;


-- Get Active users (that posted or commented something)

CREATE OR REPLACE FUNCTION find_active_users()
    RETURNS TABLE
            (
                user_id        int,
                username       varchar,
                total_posts    bigint,
                total_comments bigint
            )
AS
$$
BEGIN
    RETURN QUERY
        SELECT u.id,
               u.username,
               COUNT(DISTINCT p.id),
               COUNT(DISTINCT c.id)
        FROM "User" u
                 LEFT JOIN "Post" p ON u.id = p.user_id
                 LEFT JOIN "Comment" c ON u.id = c.user_id
        GROUP BY u.id, u.username
        HAVING (COUNT(DISTINCT p.id) > 0 AND COUNT(DISTINCT c.id) > 0);
END;
$$ LANGUAGE plpgsql;

-- Get messages from two users

CREATE OR REPLACE FUNCTION get_messages_between_users(user1_id int, user2_id int)
    RETURNS TABLE
            (
                message_id         int,
                sender_id          int,
                sender_username    varchar,
                receiver_id        int,
                receiver_username  varchar,
                message_content    text,
                message_created_at timestamp
            )
AS
$$
BEGIN
    RETURN QUERY
        SELECT m.id,
               m.sender_id,
               sender.username,
               m.receiver_id,
               receiver.username,
               m.content,
               m.created_at
        FROM "Message" m
                 JOIN "User" sender ON m.sender_id = sender.id
                 JOIN "User" receiver ON m.receiver_id = receiver.id
        WHERE (m.sender_id = user1_id AND m.receiver_id = user2_id)
           OR (m.sender_id = user2_id AND m.receiver_id = user1_id)
        ORDER BY m.created_at;
END;
$$ LANGUAGE plpgsql;

-- Get posts with like count

CREATE OR REPLACE FUNCTION get_posts_with_likes_count()
    RETURNS TABLE
            (
                post_id         int,
                post_content    text,
                author_username varchar,
                likes_count     bigint
            )
AS
$$
BEGIN
    RETURN QUERY
        SELECT p.id,
               p.content,
               u.username,
               COUNT(l.id) like_count
        FROM "Post" p
                 JOIN "User" u ON p.user_id = u.id
                 LEFT JOIN "Like" l ON p.id = l.post_id
        GROUP BY p.id, u.username
        ORDER BY like_count DESC;
END;
$$ LANGUAGE plpgsql;

-- Get user's notifications

CREATE OR REPLACE FUNCTION get_user_notifications(id_user int)
    RETURNS TABLE (content text, created_at timestamp)
AS $$
BEGIN
    RETURN QUERY
        SELECT n.content, n.created_at
        FROM "Notification" n
        WHERE n.user_id = id_user;
END;
$$ LANGUAGE plpgsql;


-- Fixtures

INSERT INTO "User" ("username", "email", "password", "created_at")
VALUES ('user1', 'user1@example.com', 'password1', NOW()),
       ('user2', 'user2@example.com', 'password2', NOW()),
       ('user3', 'user3@example.com', 'password3', NOW());

INSERT INTO "Post" ("content", "user_id", "created_at", "suspicious")
VALUES ('Sample post 1', 1, NOW(), false),
       ('Sample post 2', 1, NOW(), false),
       ('Sample post 3', 2, NOW(), true);

INSERT INTO "Comment" ("text", "user_id", "post_id", "created_at", "edited_at")
VALUES ('Comment on post 1', 2, 1, NOW(), NOW()),
       ('Comment on post 2', 1, 2, NOW(), NOW());

INSERT INTO "Like" ("user_id", "post_id", "created_at")
VALUES (1, 1, NOW()),
       (2, 1, NOW()),
       (3, 2, NOW());

INSERT INTO "Friend" ("user_id1", "user_id2")
VALUES (1, 2),
       (2, 3);

INSERT INTO "Notification" ("user_id", "content", "created_at")
VALUES (1, 'New notification 1', NOW()),
       (2, 'New notification 2', NOW());

INSERT INTO "Message" ("sender_id", "receiver_id", "content", "created_at")
VALUES (1, 2, 'Message 1', NOW()),
       (2, 1, 'Message 2', NOW());

INSERT INTO "Group" ("name", "created_at")
VALUES ('Group 1', NOW()),
       ('Group 2', NOW());

INSERT INTO "GroupMember" ("group_id", "user_id")
VALUES (1, 1),
       (1, 2),
       (2, 2),
       (2, 3);

INSERT INTO "Event" ("title", "description", "date")
VALUES ('Event 1', 'Description of Event 1', NOW()),
       ('Event 2', 'Description of Event 2', NOW());

INSERT INTO "EventParticipant" ("event_id", "user_id")
VALUES (1, 1),
       (1, 2),
       (2, 2),
       (2, 3);

INSERT INTO "Photo" ("user_id", "caption", "created_at")
VALUES (1, 'Photo 1', NOW()),
       (2, 'Photo 2', NOW());

INSERT INTO "Tag" ("name")
VALUES ('Tag 1'),
       ('Tag 2');

INSERT INTO "PostTag" ("post_id", "tag_id")
VALUES (1, 1),
       (2, 1),
       (2, 2);

INSERT INTO "Location" ("name")
VALUES ('Location 1'),
       ('Location 2');

INSERT INTO "Checkin" ("user_id", "location_id", "checkin_time")
VALUES (1, 1, NOW()),
       (2, 2, NOW());

INSERT INTO "Poll" ("question", "user_id", "created_at")
VALUES ('Poll 1', 1, NOW()),
       ('Poll 2', 2, NOW());

INSERT INTO "PollOption" ("poll_id", "option_text")
VALUES (1, 'Option 1'),
       (1, 'Option 2'),
       (2, 'Option 1');

INSERT INTO "Report" ("reason", "post_id", "reporter_id")
VALUES ('Inappropriate content', 3, 1),
       ('Spam', 3, 2);


