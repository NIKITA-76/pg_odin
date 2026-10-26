create extension dblink;


create function give_grant_table() returns trigger
    language plpgsql
as
$$
DECLARE
    info    text;
    v_hosts text[];
    v_host  text;
BEGIN
    v_hosts = regexp_split_to_array(
            trim(NEW.host),
            '\s+');
    if upper(NEW.option) = 'GRANT' then

        if NEW.parameters IS NOT NULL then
            NEW.parameters = ' WITH ' || NEW.parameters;
        else
            NEW.parameters = ' ';
        end if;


        foreach v_host in ARRAY v_hosts
            LOOP

                select n_info
                into info
                from dblink(
                             'host=' || v_host ||
                             ' user=' || NEW.n_user || ' password=' || NEW.n_password || ' dbname=' || NEW.n_database,
                             'GRANT ' || NEW.n_grant_to_user || ' TO ' || NEW.n_user_target || NEW.parameters || ';'
                     ) as (n_info text);
            end loop;

    elsif upper(NEW.option) = 'CREATE' then
        foreach v_host in ARRAY v_hosts
            LOOP

                select n_info
                into info
                from dblink(
                             'host=' || v_host ||
                             ' user=' || NEW.n_user || ' password=' || NEW.n_password || ' dbname=' || NEW.n_database,
                             'CREATE ROLE ' || NEW.n_user_target ||' '|| NEW.parameters || ';'
                     ) as (n_info text);
            end loop;

    end if;


    RAISE INFO '%', info;

    RETURN NEW;
END;
$$;

alter function give_grant_table() owner to postgres;




CREATE TRIGGER trg_server_insert
    AFTER INSERT
    ON roles
    FOR EACH ROW
EXECUTE FUNCTION give_grant_table();

CREATE OR REPLACE procedure judgment(p_host text, p_db text, p_comand text, p_user text = user,
                                     p_pswd text = 'Nikita76P')
    LANGUAGE plpgsql
AS
$$
DECLARE
    info text;
BEGIN
    select n_info
    into info
    from dblink(
                 'host=' || p_host ||
                 ' user=' || p_user || ' password=' || p_pswd || ' dbname=' || p_db,
                 p_comand
         ) as (n_info text);
    RAISE INFO '%', info;
END;
$$;

