-- transfer_chart_repository transfers the ownership of the provided chart
-- repository to the requesting user or an organization he belongs to.
create or replace function transfer_chart_repository(
    p_chart_repository_name text,
    p_user_id uuid,
    p_org_name text
) returns void as $$
declare
    v_owner_user_id uuid;
    v_owner_organization_name text;
begin
    -- Get user or organization owning the chart repository
    select cr.user_id, o.name into v_owner_user_id, v_owner_organization_name
    from chart_repository cr
    left join organization o using (organization_id)
    where cr.name = p_chart_repository_name;

    -- Check if the user doing the request is the owner or belongs to the
    -- organization which owns it
    if v_owner_organization_name is not null then
        if not user_belongs_to_organization(p_user_id, v_owner_organization_name) then
            raise insufficient_privilege;
        end if;
    elsif v_owner_user_id <> p_user_id then
        raise insufficient_privilege;
    end if;

    -- When transferring a chart repository to an organization, check the
    -- requesting user belongs to it
    if p_org_name is not null and not user_belongs_to_organization(p_user_id, p_org_name) then
        raise insufficient_privilege;
    end if;

    -- Transfer repository ownership
    if p_org_name is null then
        update chart_repository set
            user_id = p_user_id,
            organization_id = null
        where name = p_chart_repository_name;
    else
        update chart_repository set
            organization_id = (
                select organization_id from organization where name = p_org_name
            ),
            user_id = null
        where name = p_chart_repository_name;
    end if;
end
$$ language plpgsql;
