-- Start transaction and plan tests
begin;
select plan(2);

-- Declare some variables
\set org1ID '00000000-0000-0000-0000-000000000001'
\set user1ID '00000000-0000-0000-0000-000000000001'
\set user2ID '00000000-0000-0000-0000-000000000002'
\set repo1ID '00000000-0000-0000-0000-000000000001'
\set repo2ID '00000000-0000-0000-0000-000000000002'
\set optOut1ID '00000000-0000-0000-0000-000000000001'
\set optOut2ID '00000000-0000-0000-0000-000000000002'

-- Seed some data
insert into organization (organization_id, name, display_name, description, home_url)
values (:'org1ID', 'org1', 'Organization 1', 'Description 1', 'https://org1.com');
insert into "user" (user_id, alias, email)
values (:'user1ID', 'user1', 'user1@email.com');
insert into "user" (user_id, alias, email)
values (:'user2ID', 'user2', 'user2@email.com');
insert into repository (repository_id, name, display_name, url, repository_kind_id, user_id)
values (:'repo1ID', 'repo1', 'Repo 1', 'https://repo1.com', 0, :'user1ID');
insert into repository (repository_id, name, display_name, url, repository_kind_id, organization_id)
values (:'repo2ID', 'repo2', 'Repo 2', 'https://repo2.com', 0, :'org1ID');
insert into opt_out (opt_out_id, user_id, repository_id, event_kind_id)
values (:'optOut1ID', :'user1ID', :'repo1ID', 2);
insert into opt_out (opt_out_id, user_id, repository_id, event_kind_id)
values (:'optOut2ID', :'user1ID', :'repo2ID', 2);

-- Run some tests
select is(
    get_user_opt_out_entries(:'user1ID')::jsonb,
    '[{
        "opt_out_id": "00000000-0000-0000-0000-000000000001",
        "repository": {
            "repository_id": "00000000-0000-0000-0000-000000000001",
            "kind": 0,
            "name": "repo1",
            "display_name": "Repo 1",
            "user_alias": "user1",
            "organization_name": null,
            "organization_display_name": null
        },
        "event_kinds": [2]
    }, {
        "opt_out_id": "00000000-0000-0000-0000-000000000002",
        "repository": {
            "repository_id": "00000000-0000-0000-0000-000000000002",
            "kind": 0,
            "name": "repo2",
            "display_name": "Repo 2",
            "user_alias": null,
            "organization_name": "org1",
            "organization_display_name": "Organization 1"
        },
        "event_kinds": [2]
    }]'::jsonb,
    'Two opt-out entries should be returned for user1'
);
select is(
    get_user_opt_out_entries(:'user2ID')::jsonb,
    '[]',
    'No opt-out entries expected for user2'
);

-- Finish tests and rollback transaction
select * from finish();
rollback;
