/*
AREA KNOWLEDGE LIST TAXA
------------------------
Evaluate for each area and each season  knowledge level comparing old taxa count with new taxa count

ACTUAL TIME : 24minutes to create, too long...
 */
DO $$
BEGIN
    RAISE NOTICE 'INFO: (RE)CREATE MV atlas mv_area_knowledge_list_taxa';

    /* function to retrieve nomenclature value and hierarchy */
    CREATE OR REPLACE FUNCTION ref_nomenclatures.fct_c_nomenclature_value_from_hierarchy (_hierarchy varchar, _type_mnemonique text, _column text )
        RETURNS text AS $func$
DECLARE
    the_value text;
BEGIN
    EXECUTE format('SELECT  tn.%I  FROM ref_nomenclatures.t_nomenclatures tn ' || 'join ref_nomenclatures.bib_nomenclatures_types bnt on tn.id_type = bnt.id_type ' || 'where bnt.mnemonique like $1 and tn.hierarchy=$2', _column)
    USING _type_mnemonique,
    _hierarchy INTO the_value;
    RETURN the_value;
END $func$
LANGUAGE plpgsql;
    CREATE INDEX IF NOT EXISTS i_synthese_datemin_newatlas ON gn_synthese.synthese (date_min DESC NULLS LAST)
    WHERE
        synthese.date_min > '2019-01-31'::date;
    CREATE INDEX IF NOT EXISTS i_synthese_datemin_oldatlas ON gn_synthese.synthese (date_min DESC NULLS LAST)
    WHERE
        synthese.date_min <= '2019-01-31'::date;
    DROP MATERIALIZED VIEW IF EXISTS atlas.mv_data_for_atlas;
    -- some minimum date
    /* Materialized view to list all taxa in area */
    CREATE MATERIALIZED VIEW atlas.mv_data_for_atlas AS
    WITH areas AS (
        SELECT
            /* Zonages utilisés : Mailles */
            l_areas.id_area
        FROM
            ref_geo.l_areas
        WHERE
            enable IS TRUE
            AND id_type = (
                SELECT
                    id_type
                FROM
                    ref_geo.bib_areas_types
                WHERE
                    type_code = 'M10'
                LIMIT 1))
    --           , data AS (
    /* Filtrage des données et association au zonage */
    SELECT
        cor_area_synthese.id_area,
        synthese.id_synthese,
        synthese.cd_nom,
        synthese.date_min::date,
        synthese.date_min > '2019-01-31'::date AS new_data_all_period,
        synthese.date_min <= '2019-01-31'::date AS old_data_all_period,
        (tcse.bird_breed_code IS NULL
            AND extract(MONTH FROM synthese.date_min) IN (12, 1)
            AND synthese.date_min <= '2019-01-31') AS old_data_wintering,
        (tcse.bird_breed_code IS NULL
            AND extract(MONTH FROM synthese.date_min) IN (12, 1)
            AND synthese.date_min > '2019-11-30') AS new_data_wintering,
        (tcse.bird_breed_code BETWEEN 2 AND 50
            AND synthese.date_min <= '2019-01-01') AS old_data_breeding,
        (tcse.bird_breed_code BETWEEN 2 AND 50
            AND synthese.date_min > '2019-01-01') AS new_data_breeding,
        tcse.bird_breed_code
    FROM
        gn_synthese.cor_area_synthese
        JOIN areas ON areas.id_area = cor_area_synthese.id_area
        JOIN gn_synthese.synthese ON cor_area_synthese.id_synthese = synthese.id_synthese
        JOIN src_lpodatas.t_c_synthese_extended tcse ON synthese.id_synthese = tcse.id_synthese
        JOIN taxonomie.taxref ON synthese.cd_nom = taxref.cd_nom
    WHERE
        taxref.group2_inpn LIKE 'Oiseaux'
        AND taxref.cd_nom NOT IN (
            SELECT
                cd_nom
            FROM
                atlas.t_excluded_taxa);
    CREATE UNIQUE INDEX i_unique_data_for_atlas_id_synthese ON atlas.mv_data_for_atlas (id_synthese);
    CREATE INDEX i_data_for_atlas_cdnom ON atlas.mv_data_for_atlas (cd_nom);
    CREATE INDEX i_data_for_atlas_idarea ON atlas.mv_data_for_atlas (idarea);
    CREATE INDEX i_data_for_atlas_idarea ON atlas.mv_data_for_atlas (bird_breed_code);
    DROP MATERIALIZED VIEW IF EXISTS atlas.mv_area_knowledge_list_taxa;
    -- some minimum date
    /* Materialized view to list all taxa in area */
    CREATE MATERIALIZED VIEW atlas.mv_area_knowledge_list_taxa AS
    WITH atlas_code AS (
        /* Liste des codes nidif VisioNature */
        SELECT
            cd_nomenclature::int,
            hierarchy::int
        FROM
            ref_nomenclatures.t_nomenclatures n
            JOIN ref_nomenclatures.bib_nomenclatures_types t ON n.id_type = t.id_type
        WHERE
            t.mnemonique LIKE 'VN_ATLAS_CODE'
)
    SELECT
        data.id_area,
        data.cd_nom,
        taxref.lb_nom AS sci_name,
        split_part(nom_vern, ',', 1) AS common_name,
        count(id_synthese) FILTER (WHERE old_data_all_period) AS all_period_count_data_old,
        count(id_synthese) FILTER (WHERE new_data_all_period) AS all_period_count_data_new,
        extract(YEAR FROM max(data.date_min)) AS all_period_last_obs,
        count(id_synthese) FILTER (WHERE new_data_breeding) AS breeding_count_data_new,
        ref_nomenclatures.fct_c_nomenclature_value_from_hierarchy ((max(ac.hierarchy) FILTER (WHERE new_data_breeding))::text, 'VN_ATLAS_CODE', 'label_default') AS breeding_status_new,
        count(id_synthese) FILTER (WHERE old_data_breeding) AS breeding_count_data_old,
        extract(YEAR FROM (max(data.date_min) FILTER (WHERE bird_breed_code IS NOT NULL))) AS breeding_last_obs,
        ref_nomenclatures.fct_c_nomenclature_value_from_hierarchy ((max(ac.hierarchy) FILTER (WHERE old_data_breeding))::text, 'VN_ATLAS_CODE', 'label_default') AS breeding_status_old,
        count(id_synthese) FILTER (WHERE old_data_wintering) AS wintering_count_data_old,
        count(id_synthese) FILTER (WHERE new_data_wintering) AS wintering_count_data_new,
        extract(YEAR FROM (max(data.date_min) FILTER (WHERE old_data_breeding
                    OR new_data_wintering))) AS wintering_last_obs
    FROM
        atlas.mv_data_for_atlas data
        JOIN taxonomie.taxref ON data.cd_nom = taxref.cd_nom
        LEFT JOIN atlas_code ac ON ac.cd_nomenclature = data.bird_breed_code
    GROUP BY
        data.id_area,
        data.cd_nom,
        taxref.lb_nom,
        nom_vern;
    COMMENT ON MATERIALIZED VIEW atlas.mv_area_knowledge_list_taxa IS 'Synthèse de l''état des prospection par mailles comparativement à l''atlas précédent';
    CREATE UNIQUE INDEX i_area_knowledge_list_taxa_id_area_cd_nom ON atlas.mv_area_knowledge_list_taxa (id_area, cd_nom);
COMMIT;
END
$$;

