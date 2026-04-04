alter table photo_metadata drop constraint if exists photo_metadata_category_check;
alter table photo_metadata add constraint photo_metadata_category_check
    check (category in ('food', 'scenery', 'landmark', 'activity', 'people', 'miscellaneous'));
