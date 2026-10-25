create extension dblink;



CREATE OR REPLACE FUNCTION give_grant_table()
    RETURNS trigger
    LANGUAGE plpgsql
AS
$$
DECLARE
    info    text;
    v_hosts text[];
    v_host  text;
BEGIN
    if NEW.parameters IS NOT NULL then
        NEW.parameters = 'WITH ' || NEW.parameters;
    else
        NEW.parameters = '';
    end if;
    v_hosts = regexp_split_to_array(
            trim(NEW.host),
            '\s+');

    foreach v_host in ARRAY v_hosts
        LOOP

            select n_info
            into info
            from dblink(
                         'host=' || v_host ||
                         ' user=' || NEW.n_user || ' password=' || NEW.n_password || ' dbname=' || NEW.n_database,
                         'GRANT ' || NEW.n_grant_to_user || ' TO ' || NEW.n_user_target || ';'
                 ) as (n_info text);

        end loop;


    RAISE INFO '%', info;

    RETURN NEW;
END;
$$;

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

call judgment(p_host := 'db3.edi.prod.lan',
              p_db := 'coreplat_db',
              p_comand := 'select 2;
select 3;
select 5;',
              p_user := 'nikitata');

