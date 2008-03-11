!**********************************************************************
!     Sums values for daily, monthly, yearly and total flow
!     for daily mode
!***********************************************************************

      MODULE GSFSUM
      IMPLICIT NONE
!   Local Variables
      INTEGER, PARAMETER :: BALUNT = 188
      REAL, PARAMETER :: CLOSEZERO = 1.0E-15, ERRCHK = 0.00001
      INTEGER :: Nobs, Nreach
      INTEGER :: Balance_unt, Vbnm_index(10), Gsf_unt, Rpt_count
      REAL :: Cumvol_precip, Rate_precip, Cumvol_strmin, Rate_strmin
      REAL :: Cumvol_gwbndin, Rate_gwbndin, Cumvol_wellin, Rate_wellin
      REAL :: Cumvol_et, Rate_et, Cumvol_strmot, Rate_strmot
      REAL :: Cumvol_gwbndot, Rate_gwbndot, Cumvol_wellot, Rate_wellot
      REAL :: Cum_delstore, Rate_delstore, Cum_surfstor, Rate_surfstor
      REAL :: Rate_farout, Cumvol_farout, Basin_convert
      REAL :: Last_basin_soil_moist, Last_basin_ssstor
! Added lake variables
      REAL :: Rate_lakin, Rate_lakot, Cumvol_lakin, Cumvol_lakot
      REAL :: Rate_lakestor, Cum_lakestor
      REAL :: Last_basinintcpstor, Last_basinimpervstor
      REAL :: Last_basinpweqv, Last_basinsoilmoist, Last_basingravstor
      REAL :: Basin_gsfstor, Last_basinprefstor
!   Declared Variables
      REAL :: Cum_soilstor, Rate_soilstor, Cum_uzstor, Rate_uzstor
      REAL :: Cum_satstor, Rate_satstor, Cum_pweqv, Rate_pweqv
      REAL :: Basinpweqv, Basinsoilstor, Uzf_infil, Ave_uzf_infil
      REAL :: Basinppt, Basinpervet, Basinimpervevap, Basinintcpevap
      REAL :: Basinsnowevap, Basinstrmflow, Basinsz2gw, Basingw2sz
      REAL :: Uzf_recharge, Basinseepout, Basinsoilmoist, Basingravstor
      REAL :: Basingwstor, Basinintcpstor, Basinimpervstor
      REAL :: Basininterflow, Basinsroff, Strm_stor, Lake_stor
      REAL :: Obs_strmflow, Basinszreject, Basinprefstor, Uzf_et
      REAL :: Basinrain, Basinsnow, Basingvr2pfr, Basinslowflow
      REAL :: Basinprefflow, Basinhortonian, Basinhortonianlakes
      REAL :: Basinlakeinsz, Basinlakeevap, Basinlakeprecip
      REAL :: Uzf_del_stor, Streambed_loss, Gwflow2strms
      REAL :: Sfruz_change_stor, Lakebed_loss, Lake_change_stor
      REAL :: Gwflow2lakes, Basininfil, Basindunnian, Basinsm2gvr
      REAL :: Basingvr2sm, Basininfil_tot, Basininfil2pref, Basindnflow
      REAL :: Basinactet, Basinsnowmelt, Sfruz_tot_stor
      REAL :: Basinfarfieldflow, Basinsoiltogw
!   Declared Variables from other modules - obs
      REAL, ALLOCATABLE :: Runoff(:)
!   Declared Variables from other modules - precip
      REAL :: Basin_ppt, Basin_rain, Basin_snow
!   Declared Variables from other modules - soilzone
      REAL :: Basin_perv_et, Basin_soil_moist, Basin_sz2gw, Basin_gw2sm
      REAL :: Basin_ssstor, Basin_ssflow, Basin_actet, Basin_dnflow
      REAL :: Basin_dunnian, Basin_sm2gvr, Basin_pref_stor
      REAL :: Basin_infil_tot, Basin_pref_flow_in, Basin_gvr2sm
      REAL :: Basin_gvr2pfr, Basin_slowflow, Basin_prefflow
      REAL :: Basin_lakeinsz, Basin_lakeprecip, Basin_soil_to_gw
      REAL :: Basin_szfarflow
!   Declared Variables from other modules - snow
      REAL :: Basin_snowevap, Basin_pweqv, Basin_snowmelt
!   Declared Variables from other modules - basin
      INTEGER :: Prt_debug
      REAL :: Basin_area_inv
!   Declared Variables from other modules - cascade
      INTEGER :: Outflow_flg
!   Declared Variables from other modules - srunoff
      REAL :: Basin_sroff, Basin_imperv_evap, Basin_imperv_stor
      REAL :: Basin_infil, Basin_hortonian, Basin_hortonian_lakes
      REAL :: Strm_farfield
!   Declared Variables from other modules - strmflow
      REAL :: Basin_cfs
!   Declared Variables from other modules - gwflow
!     REAL :: Basin_gwstor
!   Declared Variables from other modules - intcp
      REAL :: Basin_intcp_evap, Basin_intcp_stor
!   Declared Variables from other modules - gsflow_budget
      REAL :: Sat_store, Unsat_store, Basin_szreject, Basin_lakeevap
      REAL :: Stream_leakage, Basin_reach_latflow, Sat_change_stor
!   Declared Parameters
      INTEGER :: Id_obsrunoff, Runoff_units
!   Control Parameters
      INTEGER :: Rpt_days, Gsf_rpt
      CHARACTER(LEN=256) :: Csv_output_file, Gsflow_output_file
      CHARACTER(LEN=256) :: Model_output_file
      END MODULE GSFSUM

!***********************************************************************
!     Main gsflow_sum routine
!***********************************************************************
      INTEGER FUNCTION gsflow_sum(Arg)
      IMPLICIT NONE
! Arguments
      CHARACTER(LEN=*), INTENT(IN) :: Arg
! Functions
      INTEGER, EXTERNAL :: gsfsumdecl, gsfsuminit, gsfsumrun
      INTEGER, EXTERNAL :: gsfsumclean
!***********************************************************************
      gsflow_sum = 0

      IF ( Arg.EQ.'run' ) THEN
        gsflow_sum = gsfsumrun()
      ELSEIF ( Arg.EQ.'declare' ) THEN
        gsflow_sum = gsfsumdecl()
      ELSEIF ( Arg.EQ.'initialize' ) THEN
        gsflow_sum = gsfsuminit()
      ELSEIF ( Arg.EQ.'cleanup' ) THEN
        gsflow_sum = gsfsumclean()
      ENDIF

      END FUNCTION gsflow_sum

!***********************************************************************
!     gsfsumdecl - set up basin summary parameters
!   Declared Parameters
!     id_obsrunoff, runoff_units
!   Declared Control Parameters
!     rpt_days, csv_output_file, gsflow_output_file, model_output_file
!***********************************************************************
      INTEGER FUNCTION gsfsumdecl()
      USE GSFSUM
      IMPLICIT NONE
      INCLUDE 'fmodules.inc'
!***********************************************************************
      gsfsumdecl = 1

      IF ( declmodule(
     &'$Id: gsflow_sum.f 3810 2008-02-07 16:30:09Z rsregan $')
     &     .NE.0 ) RETURN

      Nobs = getdim('nobs')
      IF ( Nobs.EQ.-1 ) RETURN

      Nreach = getdim('nreach')
      IF ( Nreach.EQ.-1 ) RETURN

      IF ( declvar('gsflow_sum', 'basinfarfieldflow', 'one', 1, 'real',
     &     'Volumetric flow rate of PRMS interflow and surface runoff'//
     &     ' leaving modeled region as far-field flow',
     &     'L3/T',
     &     Basinfarfieldflow).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basinsoiltogw', 'one', 1, 'real',
     &     'Volumetric flow rate of direct gravity drainage from'//
     &     ' excess capillary water to the unsaturated zone',
     &     'L3/T',
     &     Basinsoiltogw).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basinppt', 'one', 1, 'real',
     &     'Volumetric flow rate of precipitation on modeled region',
     &     'L3/T',
     &     Basinppt).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basinsnow', 'one', 1, 'real',
     &     'Volumetric flow rate of snow on modeled region',
     &     'L3/T',
     &     Basinsnow).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basinrain', 'one', 1, 'real',
     &     'Volumetric flow rate of rain on modeled region',
     &     'L3/T',
     &     Basinrain).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basinpervet', 'one', 1, 'real',
     &     'Volumetric flow rate of evapotranspiration from pervious'//
     &     ' areas', 'L3/T',
     &     Basinpervet).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basinimpervevap', 'one', 1, 'real',
     &     'Volumetric flow rate of evaporation from impervious areas',
     &     'L3/T',
     &     Basinimpervevap).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basinintcpevap', 'one', 1, 'real',
     &     'Volumetric flow rate of evaporation of intercepted'//
     &     ' precipitation', 'L3/T',
     &     Basinintcpevap).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basinsnowevap', 'one', 1, 'real',
     &     'Volumetric flow rate of snowpack sublimation', 'L3/T',
     &     Basinsnowevap).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basinlakeevap', 'one', 1, 'real',
     &     'Volumetric flow rate of evaporation from lakes',
     &     'L3/T',
     &     Basinlakeevap).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basinlakeprecip', 'one', 1, 'real',
     &     'Volumetric flow rate of precipitation on lakes',
     &     'L3/T',
     &     Basinlakeprecip).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basinstrmflow', 'one', 1, 'real',
     &     'Volumetric flow rate of streamflow leaving modeled region',
     &     'L3/T',
     &     Basinstrmflow).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basinsz2gw', 'one', 1, 'real',
     &     'Potential volumetric flow rate of gravity drainage from'//
     &     ' the soil zone to the unsaturated zone (before conditions'//
     &     ' of the unsaturated and saturated zones are applied)',
     &     'L3/T',
     &     Basinsz2gw).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basingw2sz', 'one', 1, 'real',
     &     'Volumetric flow rate of ground-water discharge from the'//
     &     ' saturated zone to the soil zone', 'L3/T',
     &     Basingw2sz).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'uzf_recharge', 'one', 1, 'real',
     &     'Volumetric flow rate of recharge from the unsaturated'//
     &     ' zone to the saturated zone', 'L3/T',
     &     Uzf_recharge).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basinseepout', 'one', 1, 'real',
     &     'Volumetric flow rate of ground-water discharge from the'//
     &     ' saturated zone to the soil zone', 'L3/T',
     &     Basinseepout).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basinsoilmoist', 'one', 1, 'real',
     &     'Volume of water in capillary reservoirs of the soil zone',
     &     'L3',
     &     Basinsoilmoist).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basingravstor', 'one', 1, 'real',
     &     'Volume of water in gravity reservoirs of the soil zone',
     &     'L3',
     &     Basingravstor).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basingwstor', 'one', 1, 'real',
     &     'Volume of water in PRMS ground-water reservoirs'//
     &     ' (PRMS-only simulations)', 'L3',
     &     Basingwstor).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basinintcpstor', 'one', 1, 'real',
     &     'Volume of intercepted percipitation in plant-canopy'//
     &     ' reservoirs', 'L3',
     &     Basinintcpstor).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basinimpervstor', 'one', 1, 'real',
     &     'Volume of water in impervious reservoirs', 'L3',
     &     Basinimpervstor).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basininterflow', 'one', 1, 'real',
     &     'Volumetric flow rate of slow interflow to streams', 'L3/T',
     &     Basininterflow).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basinsroff', 'one', 1, 'real',
     &     'Volumetric flow rate of surface runoff to streams', 'L3/T',
     &     Basinsroff).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basinhortonianlakes', 'one', 1,'real',
     &     'Volumetric flow rate of Hortonian surface runoff to lakes',
     &     'L3/T',
     &     Basinhortonianlakes).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basinlakeinsz', 'one', 1,'real',
     &     'Volumetric flow rate of interflow and Dunnian surface'//
     &     ' runoff to lakes',
     &     'L3/T',
     &     Basinlakeinsz).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'strm_stor', 'one', 1, 'real',
     &     'Volume of water in streams', 'L3',
     &     Strm_stor).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'lake_stor', 'one', 1, 'real',
     &     'Volume of water in lakes', 'L3',
     &     Lake_stor).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'obs_strmflow', 'one', 1, 'real',
     &     'Volumetric flow rate of streamflow measured at a gaging'//
     &     ' station', 'L3/T',
     &     Obs_strmflow).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basinszreject', 'one', 1, 'real',
     &     'Volumetric flow rate of gravity drainage from the soil'//
     &     ' zone not accepted due to conditions in the unsaturated'//
     &     ' and saturated zones', 'L3/T',
     &     Basinszreject).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basinprefstor', 'one', 1, 'real',
     &     'Volume of water stored in preferential-flow reservoirs of'//
     &     ' the soil zone', 'L3',
     &     Basinprefstor).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'uzf_et', 'one', 1, 'real',
     &     'Volumetric flow rate of evapotranspiration from the'//
     &     ' unsaturated and saturated zones', 'L3/T',
     &     Uzf_et).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'uzf_del_stor', 'one', 1, 'real',
     &     'Change in unsaturated-zone storage', 'L3',
     &     Uzf_del_stor).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'uzf_infil', 'one', 1, 'real',
     &     'Volumetric flow rate of gravity drainage to the'//
     &     ' unsaturated and saturated zones', 'L3/T',
     &     Uzf_infil).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'streambed_loss', 'one', 1, 'real',
     &     'Volumetric flow rate of stream leakage to the'//
     &     ' unsaturated and saturated zones', 'L3/T',
     &     Streambed_loss).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'sfruz_change_stor', 'one', 1, 'real',
     &     'Change in unsaturated-zone storage under streams', 'L3',
     &     Sfruz_change_stor).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'gwflow2strms', 'one', 1, 'real',
     &     'Volumetric flow rate of ground-water discharge to streams',
     &     'L3/T',
     &     Gwflow2strms).NE.0 ) RETURN
     
      IF ( declvar('gsflow_sum', 'sfruz_tot_stor', 'one', 1, 'real',
     &     'Volume of water in the unsaturated zone beneath streams',
     &     'L3',
     &     Sfruz_tot_stor).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'lakebed_loss', 'one', 1, 'real',
     &     'Volumetric flow rate of lake leakage to the unsaturated'//
     &     ' and saturated zones', 'L3/T',
     &     Lakebed_loss).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'lake_change_stor', 'one', 1, 'real',
     &     'Change in lake storage', 'L3',
     &     Lake_change_stor).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'gwflow2lakes', 'one', 1, 'real',
     &     'Volumetric flow rate of ground-water discharge to lakes',
     &     'L3/T',
     &     Gwflow2lakes).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basininfil', 'one', 1, 'real',
     &     'Volumetric flow rate of soil infiltration including'//
     &     ' precipitation, snowmelt, and cascading Hortonian flow',
     &     'L3/T',
     &     Basininfil).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basindunnian', 'one', 1, 'real',
     &     'Volumetric flow rate of Dunnian runoff to streams', 'L3/T',
     &     Basindunnian).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basinsm2gvr', 'one', 1, 'real',
     &     'Volumetric flow rate of flow from capillary reservoirs to'//
     &     ' gravity reservoirs', 'L3/T',
     &     Basinsm2gvr).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basingvr2sm', 'one', 1, 'real',
     &     'Volumetric flow rate of flow from gravity reservoirs to'//
     &     ' capillary reservoirs', 'L3/T',
     &     Basingvr2sm).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basininfil_tot', 'one', 1, 'real',
     &     'Volumetric flow rate of soil infiltration into capillary'//
     &     ' reservoirs including precipitation, snowmelt, and'//
     &     ' cascading Hortonian and Dunnian runoff and interflow'//
     &     ' minus infiltration to preferential-flow reservoirs',
     &     'L3/T',
     &     Basininfil_tot).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basininfil2pref', 'one', 1, 'real',
     &     'Volumetric flow rate of soil infiltration into'//
     &     ' preferential-flow reservoirs including precipitation,'//
     &     ' snowmelt, and cascading surface runoff', 'L3/T',
     &     Basininfil2pref).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basindnflow', 'one', 1, 'real',
     &     'Volumetric flow rate of cascading Dunnian runoff and'//
     &     ' interflow to HRUs', 'L3/T',
     &     Basindnflow).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basinactet', 'one', 1, 'real',
     &     'Volumetric flow rate of actual evaporation from HRUS',
     &     'L3/T',
     &     Basinactet).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basinsnowmelt', 'one', 1, 'real',
     &     'Volumetric flow rate of snowmelt', 'L3/T',
     &     Basinsnowmelt).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'ave_uzf_infil', 'one', 1, 'real',
     &     'Running average infiltration to UZF cell', 'L3',
     &     Ave_uzf_infil).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'cum_pweqv', 'one', 1, 'real',
     &     'Cumulative change in snowpack storage in MODFLOW units',
     &     'L3', Cum_pweqv).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'cum_soilstor', 'one', 1, 'real',
     &     'Cumulative change in soil storage in MODFLOW units', 'L3',
     &     Cum_soilstor).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'cum_uzstor', 'one', 1, 'real',
     &     'Cumulative change in unsaturated storage', 'L3',
     &     Cum_uzstor).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'cum_satstor', 'one', 1, 'real',
     &     'Cumulative change in saturated storage', 'L3',
     &     Cum_satstor).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'rate_pweqv', 'one', 1, 'real',
     &     'Change in snow pack storage in MODFLOW units', 'L3',
     &     Rate_pweqv).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'rate_soilstor', 'one', 1, 'real',
     &     'Change in soil storage in MODFLOW units', 'L3',
     &     Rate_soilstor).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'rate_uzstor', 'one', 1, 'real',
     &     'Change in unsaturated storage', 'L3',
     &     Rate_uzstor).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'rate_satstor', 'one', 1, 'real',
     &     'Change in saturated storage', 'L3',
     &     Rate_satstor).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basinpweqv', 'one', 1, 'real',
     &     'Volume of water in snowpack storage', 'L3',
     &     Basinpweqv).NE.0 ) RETURN

      IF ( declvar('gsflow_sum', 'basinsoilstor', 'one', 1, 'real',
     &     'Soil moisture storage in volume of MODFLOW units', 'L3',
     &     Basinsoilstor).NE.0 ) RETURN

      IF ( declparam('gsflow_sum', 'id_obsrunoff', 'one', 'integer',
     &     '0', 'bounded', 'nobs',
     &     'Index of basin outlet observed runoff station',
     &     'Index of basin outlet observed runoff station',
     &     'none').NE.0 ) RETURN

      IF ( declparam('gsflow_sum', 'runoff_units', 'one', 'integer',
     &     '0', '0', '1',
     &     'Observed runoff units',
     &     'Observed runoff units (0=cfs; 1=cms)',
     &     'none').NE.0 ) RETURN

      IF ( Nobs.GT.0 ) ALLOCATE (Runoff(Nobs))

      gsfsumdecl = 0

      END FUNCTION gsfsumdecl

!***********************************************************************
!     gsfsuminit - Initialize basinsum module - get parameter values
!                set to zero
!***********************************************************************
      INTEGER FUNCTION gsfsuminit()
      USE GSFSUM
      USE GSFCONVERT, ONLY:Acre_inches_to_mfl3
      IMPLICIT NONE
      INCLUDE 'fmodules.inc'
      EXTERNAL GSF_PRINT
!***********************************************************************
      gsfsuminit = 1

      IF ( getparam('gsflow_sum', 'id_obsrunoff', 1, 'integer',
     &     Id_obsrunoff).NE.0 ) RETURN
      IF ( Id_obsrunoff.EQ.0 ) Id_obsrunoff = 1

      IF ( getparam('gsflow_sum', 'runoff_units', 1, 'real',
     &     Runoff_units).NE.0 ) RETURN

      IF ( getvar('basin', 'prt_debug', 1, 'integer', Prt_debug)
     &     .NE.0 ) RETURN
      IF ( Prt_debug.EQ.1 ) THEN
        OPEN (BALUNT, FILE='gsflow_sum.wbal')
        WRITE (BALUNT, 9001)
      ENDIF
      IF ( getvar('cascade', 'outflow_flg', 1, 'integer', Outflow_flg)
     &     .NE.0 ) RETURN

      IF ( getvar('basin', 'basin_area_inv', 1, 'real', Basin_area_inv)
     &     .NE.0 ) RETURN
      Basin_convert = Acre_inches_to_mfl3/Basin_area_inv

!  Set the volume budget indicies to -1 anytime "init" is called.
!  This will make "run" figure out the vbnm order.
      Vbnm_index = -1

!  Put a header on the output file when the model starts.
      CALL GSF_PRINT()

!  Initialize cumulative GSF report variables to 0.0
      Cumvol_precip = 0.0
      Cumvol_strmin = 0.0
      Cumvol_gwbndin = 0.0
      Cumvol_wellin = 0.0
      Cumvol_et = 0.0
      Cumvol_strmot = 0.0
      Cumvol_gwbndot = 0.0
      Cumvol_wellot = 0.0
      Cumvol_farout = 0.0
      Cum_delstore = 0.0
      Cum_surfstor = 0.0
      Cum_soilstor = 0.0
      Cum_uzstor = 0.0
      Cum_satstor = 0.0
      Cum_pweqv = 0.0
      Rate_soilstor = 0.0
      Rate_uzstor = 0.0
      Rate_satstor = 0.0
      Rate_pweqv = 0.0
      Rate_farout = 0.0
      Uzf_infil = 0.0
      Ave_uzf_infil = 0.0
      Lakebed_loss = 0.0
      Lake_change_stor = 0.0
      Basinppt = 0.0
      Basinpervet = 0.0
      Basinimpervevap = 0.0
      Basinintcpevap = 0.0
      Basinsnowevap = 0.0
      Basinlakeevap = 0.0
      Basinlakeprecip = 0.0
      Basinstrmflow = 0.0
      Basinsz2gw = 0.0
      Basingw2sz = 0.0
      Uzf_recharge = 0.0
      Basinseepout = 0.0
      Basinsoilmoist = 0.0
      Basingravstor = 0.0
      Basingwstor = 0.0
      Basinintcpstor = 0.0
      Basinimpervstor = 0.0
      Basinpweqv = 0.0
      Basininterflow = 0.0
      Basinsroff = 0.0
      Basinhortonianlakes = 0.0
      Basinlakeinsz = 0.0
      Strm_stor = 0.0
      Lake_stor = 0.0
      Obs_strmflow = 0.0
      Basinszreject = 0.0
      Basinprefstor = 0.0
      Uzf_et = 0.0
      Uzf_del_stor = 0.0
      Streambed_loss = 0.0
      Sfruz_change_stor = 0.0
      Gwflow2strms = 0.0
      Sfruz_tot_stor = 0.0
      Gwflow2lakes = 0.0
      Basininfil = 0.0
      Basindunnian = 0.0
      Basinsm2gvr = 0.0
      Basingvr2sm = 0.0
      Basininfil_tot = 0.0
      Basininfil2pref = 0.0
      Basinfarfieldflow = 0.0
      Basinsoiltogw = 0.0
      Strm_farfield = 0.0
! Added lake variables
      Rate_lakin = 0.0
      Rate_lakot = 0.0
      Cumvol_lakin = 0.0
      Cumvol_lakot = 0.0
      Rate_lakestor = 0.0
      Cum_lakestor = 0.0

      CALL BASIN_GET_STORAGE

! LAND SURFACE STORAGE
      Last_basinintcpstor = Basinintcpstor
      Last_basinimpervstor = Basinimpervstor
      Last_basinpweqv = Basinpweqv
      Last_basin_soil_moist = Basin_soil_moist
      Last_basin_ssstor = Basin_ssstor

! SOIL STORAGE
      Last_basinsoilmoist = Basinsoilmoist
      Last_basingravstor = Basingravstor
      Last_basinprefstor = Basinprefstor

      Rpt_count = 0
            
      gsfsuminit = 0

 9001 FORMAT('    Date         SZ Bal    lakeinsz     Dunnian',
     &       '    Slowflow    prefflow      pervet       infil',
     &       '   soilmoist Last_soilmoist gravstor Last_gravstor',
     &       '     gw2sz       sz2gw    szreject    soiltogw',
     &       '     farflow  farflowtot')
      END FUNCTION gsfsuminit

!***********************************************************************
!     gsfsumrun - Computes summary values
!***********************************************************************
      INTEGER FUNCTION gsfsumrun()
      USE GSFSUM
      USE GSFCONVERT, ONLY:Mfl3t_to_cfs, Mfl3_to_ft3, Cfs2inches
      USE GSFPRMS2MF, ONLY:Net_sz2gw
      USE GSFBUDGET, ONLY:Gw_inout, Gw_bnd_in, Gw_bnd_out, Well_in,
     &    Well_out, Stream_inflow, Basin_actetgw
      USE GWFBASMODULE, ONLY:DELT
      USE GLOBAL, ONLY:IUNIT
      USE GWFUZFMODULE, ONLY:UZTSRAT
      USE GWFSFRMODULE, ONLY:SFRUZBD, STRMDELSTOR_RATE
      USE GWFLAKMODULE, ONLY:TOTGWIN_LAK, TOTGWOT_LAK, TOTDELSTOR_LAK,
     &                       TOTSTOR_LAK, TOTWTHDRW_LAK
!rsr &           , TOTRUNF_LAK, TOTSURFIN_LAK, TOTPPT_LAK, TOTSURFOT_LAK
      USE GSFMODFLOW, ONLY:KKSTP, KKPER, KKITER
      IMPLICIT NONE
      INTRINSIC SNGL
      INCLUDE 'fmodules.inc'
! Local variables
      INTEGER :: nowtime(6), year, mo, day, nstep
      REAL :: obsq_cfs, obsq_cms
!     REAL :: gw_out, basinreachlatflowm3
      REAL :: sz_bal, et, rnf, gvf, szin, szout, szdstor
!***********************************************************************
      gsfsumrun = 1

!*****Evapotranspiration
      IF ( getvar('soilzone', 'basin_perv_et', 1, 'real', Basin_perv_et)
     &     .NE.0 ) RETURN
      IF ( getvar('snow', 'basin_snowevap', 1, 'real', Basin_snowevap)
     &     .NE.0 ) RETURN
      IF ( getvar('srunoff', 'basin_imperv_evap', 1, 'real',
     &     Basin_imperv_evap).NE.0 ) RETURN
      IF ( getvar('intcp', 'basin_intcp_evap', 1, 'real',
     &     Basin_intcp_evap).NE.0 ) RETURN
      IF ( getvar('soilzone', 'basin_lakeevap', 1, 'real',
     &     Basin_lakeevap).NE.0 ) RETURN

      ! basin_actet only includes land HRU ET
      IF ( getvar('soilzone', 'basin_actet', 1, 'real', Basin_actet)
     &     .NE.0 ) RETURN

      Uzf_et = SNGL(UZTSRAT(2)) !???does this equal sum of actet_gw
      et = Basin_actetgw*Basin_convert
!     print *, 'uzfet', uzf_et-et, uzf_et, et

! convert PRMS variables acre-inches over the basin area (depth)
! to modflow length cubed (total volume)
      Basinpervet = Basin_perv_et*Basin_convert
      Basinimpervevap = Basin_imperv_evap*Basin_convert
      Basinintcpevap = Basin_intcp_evap*Basin_convert
      Basinsnowevap = Basin_snowevap*Basin_convert
      Basinlakeevap = Basin_lakeevap*Basin_convert
      Basinactet = Basin_actet*Basin_convert + Uzf_et + Basinlakeevap

! STREAMFLOW

! convert basin_cfs from cfs over to modflow l3/t (volume per time step)
      IF ( getvar('strmflow', 'basin_cfs', 1, 'real', Basin_cfs)
     &     .NE.0 ) RETURN
      Basinstrmflow = Basin_cfs/Mfl3t_to_cfs

      IF ( Nobs.LT.1 ) THEN
        obsq_cfs = -1.0
      ELSE
        IF ( getvar('obs', 'runoff', Nobs, 'real', Runoff).NE.0 ) RETURN
        IF ( Runoff_units.EQ.1 ) THEN
          obsq_cms = Runoff(Id_obsrunoff)
          obsq_cfs = obsq_cms*Mfl3_to_ft3
        ELSE
          obsq_cfs = Runoff(Id_obsrunoff)
        ENDIF
      ENDIF
      Obs_strmflow = obsq_cfs/Mfl3t_to_cfs

      IF ( getvar('gsflow', 'basin_reach_latflow', 1, 'real',
     &     Basin_reach_latflow).NE.0 ) RETURN
!rsr  basinreachlatflowm3 = Basin_reach_latflow/Mfl3t_to_cfs

! PRECIPITATION
! DANGER markstro convert Basin_ppt from acre-inches over the
!                 basin area (depth) to m3 (total volume)
      IF ( getvar('precip', 'basin_ppt', 1, 'real', Basin_ppt)
     &     .NE.0 ) RETURN
      IF ( getvar('precip', 'basin_rain', 1, 'real', Basin_rain)
     &     .NE.0 ) RETURN
      IF ( getvar('precip', 'basin_snow', 1, 'real', Basin_snow)
     &     .NE.0 ) RETURN
      IF ( getvar('gsfbud', 'basin_lakeprecip', 1, 'real',
     &     Basin_lakeprecip).NE.0 ) RETURN
      !Basinppt includes precipitation on lakes
      Basinppt = Basin_ppt*Basin_convert
      Basinrain = Basin_rain*Basin_convert
      Basinsnow = Basin_snow*Basin_convert
      Basinlakeprecip = Basin_lakeprecip*Basin_convert

! SOIL/RUNOFF TOTALS

      !flows to streams
      IF ( getvar('srunoff', 'basin_sroff', 1, 'real', Basin_sroff)
     &     .NE.0 ) RETURN
      IF ( getvar('srunoff', 'basin_hortonian', 1, 'real',
     &     Basin_hortonian).NE.0 ) RETURN
      IF ( getvar('soilzone', 'basin_dunnian', 1, 'real', Basin_dunnian)
     &     .NE.0 ) RETURN
      IF ( getvar('soilzone', 'basin_ssflow', 1, 'real', Basin_ssflow)
     &     .NE.0 ) RETURN
      IF ( getvar('soilzone', 'basin_slowflow', 1, 'real',
     &     Basin_slowflow).NE.0 ) RETURN
      IF ( getvar('soilzone', 'basin_prefflow', 1, 'real',
     &     Basin_prefflow).NE.0 ) RETURN
      Basinsroff = Basin_sroff*Basin_convert  !Hortonian and Dunnian
      Basinhortonian = Basin_hortonian*Basin_convert
      Basindunnian = Basin_dunnian*Basin_convert
      Basininterflow = Basin_ssflow*Basin_convert !slow + pref
      Basinslowflow = Basin_slowflow*Basin_convert
      Basinprefflow = Basin_prefflow*Basin_convert
      !flows to lakes
      IF ( getvar('srunoff', 'basin_hortonian_lakes', 1, 'real',
     &     Basin_hortonian_lakes).NE.0 ) RETURN
      IF ( getvar('soilzone', 'basin_lakeinsz', 1, 'real',
     &     Basin_lakeinsz).NE.0 ) RETURN
      Basinhortonianlakes = Basin_hortonian_lakes*Basin_convert
      Basinlakeinsz = Basin_lakeinsz*Basin_convert    !interflow + Dunnian soilzone

! SOIL/GW TOTALS
      !flows to soilzone
      IF ( getvar('srunoff', 'basin_infil', 1, 'real', Basin_infil)
     &     .NE.0 ) RETURN
      IF ( getvar('soilzone', 'basin_gw2sm', 1, 'real', Basin_gw2sm)
     &     .NE.0 ) RETURN
      IF ( getvar('soilzone', 'basin_infil_tot', 1, 'real',
     &     Basin_infil_tot).NE.0 ) RETURN
      IF ( getvar('soilzone', 'basin_pref_flow_in', 1, 'real',
     &     Basin_pref_flow_in).NE.0 ) RETURN
      IF ( getvar('snow', 'basin_snowmelt', 1, 'real', Basin_snowmelt)
     &     .NE.0 ) RETURN
      Basininfil = Basin_infil*Basin_convert !to capillary and preferential
      Basingw2sz = Basin_gw2sm*Basin_convert !to gravity
      Basininfil_tot = Basin_infil_tot*Basin_convert !infil plus cascading flow to capillary
      Basininfil2pref = Basin_pref_flow_in*Basin_convert !portion of infil to preferential
      Basinsnowmelt = Basin_snowmelt*Basin_convert

      !flows from soilzone
      IF ( getvar('soilzone', 'basin_sz2gw', 1, 'real', Basin_sz2gw)
     &     .NE.0 ) RETURN
      IF ( getvar('soilzone', 'basin_szreject', 1, 'real',
     &     Basin_szreject).NE.0 ) RETURN
      IF ( getvar('soilzone', 'basin_soil_to_gw', 1, 'real',
     &     Basin_soil_to_gw).NE.0 ) RETURN
      IF ( getvar('soilzone', 'basin_szfarflow', 1, 'real',
     &     Basin_szfarflow).NE.0 ) RETURN
      Basinsoiltogw = Basin_soil_to_gw*Basin_convert
      Basinsz2gw = Basin_sz2gw*Basin_convert
      Basinszreject = Basin_szreject*Basin_convert

      !internal soilzone flows
      IF ( getvar('soilzone', 'basin_sm2gvr', 1, 'real', Basin_sm2gvr)
     &     .NE.0 ) RETURN
      IF ( getvar('soilzone', 'basin_gvr2sm', 1, 'real', Basin_gvr2sm)
     &     .NE.0 ) RETURN
      IF ( getvar('soilzone', 'basin_gvr2pfr', 1, 'real', Basin_gvr2pfr)
     &     .NE.0 ) RETURN
      IF ( getvar('soilzone', 'basin_dnflow', 1, 'real', Basin_dnflow)
     &     .NE.0 ) RETURN
      Basinsm2gvr = Basin_sm2gvr*Basin_convert !> field capacity
      Basingvr2sm = Basin_gvr2sm*Basin_convert !replenish soil moist
      Basingvr2pfr = Basin_gvr2pfr*Basin_convert !>pref_flow threshold
      Basindnflow = Basin_dnflow*Basin_convert !cascading slow, pref, and Dunnian

      !flows from PRMS that go outside of basin and not to MODFLOW
      IF ( Outflow_flg==1 ) THEN
        IF ( getvar('srunoff', 'strm_farfield', 1, 'real',
     &       Strm_farfield).NE.0 ) RETURN
        Basinfarfieldflow = Strm_farfield/Mfl3t_to_cfs
      ENDIF
      
!  Stuff from MODFLOW
      IF ( Vbnm_index(1).EQ.-1 ) CALL MODFLOW_VB_DECODE(Vbnm_index)

      IF ( getvar('gsfbud', 'sat_change_stor', 1, 'real',
     &     Sat_change_stor).NE.0 ) RETURN

      IF ( getvar('gsfbud', 'stream_leakage', 1, 'real', Stream_leakage)
     &     .NE.0 ) RETURN

      Uzf_recharge = SNGL(UZTSRAT(3))
      Basinseepout = SNGL(UZTSRAT(5))
      Uzf_infil = SNGL(UZTSRAT(1))
      Uzf_del_stor = SNGL(UZTSRAT(4))

      Streambed_loss = SFRUZBD(4)
      Sfruz_change_stor = SFRUZBD(5)
      Gwflow2strms = SFRUZBD(8)
      sfruz_tot_stor = SFRUZBD(10)

      nstep = getstep()
      IF ( nstep.GT.1 ) THEN
        Ave_uzf_infil = (Ave_uzf_infil*(nstep-1)) + Basin_sz2gw -
     &                  Basin_szreject
      ELSE
        Ave_uzf_infil = Basin_sz2gw - Basin_szreject
      ENDIF
      Ave_uzf_infil = Ave_uzf_infil/nstep

      IF ( IUNIT(22).GT.0 ) THEN
        Lake_stor = TOTSTOR_LAK
        Gwflow2lakes = TOTGWIN_LAK 
        Lakebed_loss = TOTGWOT_LAK
        Lake_change_stor = TOTDELSTOR_LAK
      ENDIF

      CALL MODFLOW_SFR_GET_STORAGE

      CALL BASIN_GET_STORAGE

      CALL dattim('now', nowtime)
      year = nowtime(1)
      mo = nowtime(2)
      day = nowtime(3)

      IF ( Prt_debug==1 ) THEN
        et = Basin_perv_et + Basin_snowevap + Basin_imperv_evap +
     &       Basin_intcp_evap
        IF ( ABS(Basin_actet-et)>ERRCHK ) THEN
          WRITE (BALUNT, *) 'ET', Basin_actet - et, Basin_actet, et
          WRITE (BALUNT, *) 'ET', Basin_perv_et, Basin_snowevap,
     &                      Basin_imperv_evap, Basin_intcp_evap,
     &                      Basin_lakeevap, Uzf_et
        ENDIF

        rnf = Basin_hortonian + Basin_dunnian - Basin_sroff
        IF ( ABS(rnf)>ERRCHK ) WRITE (BALUNT, *) 'runoff', rnf,
     &       Basin_hortonian, Basin_dunnian, Basin_sroff
        gvf = Basin_slowflow + Basin_prefflow - Basin_ssflow
        IF ( ABS(gvf)>ERRCHK ) WRITE (BALUNT, *) 'gravflow', gvf,
     &       Basin_slowflow, Basin_prefflow, Basin_ssflow

        szin = Basin_infil + Basin_gw2sm + Basin_szreject
        szdstor = Last_basin_soil_moist + Last_basin_ssstor
     &            - Basin_soil_moist - Basin_ssstor
        szout = Basin_sz2gw + Basin_ssflow + Basin_lakeinsz +
     &          Basin_dunnian + Basin_perv_et + Basin_szfarflow
     &          + Basin_soil_to_gw
        IF ( ABS(szin-szout+szdstor)/Basin_soil_moist>ERRCHK ) THEN
          WRITE (BALUNT, 9002) year, mo, day
          WRITE (BALUNT, *) 'SZ flow', szin-szout+szdstor, szin, szout,
     &                      szdstor
          WRITE (BALUNT, *) 'SZ flow', Basin_infil, Basin_gw2sm,
     &                      Basin_szreject, Last_basin_soil_moist,
     &                      Last_basin_ssstor, Basin_soil_moist,
     &                      Basin_ssstor, Basin_sz2gw, Basin_ssflow,
     &                      Basin_lakeinsz, Basin_dunnian,
     &                      Basin_perv_et, Basin_szfarflow,
     &                      Basin_soil_to_gw
        ENDIF

        sz_bal = Basinlakeinsz + Basindunnian + Basinslowflow +
     &           Basinprefflow + Basinpervet - Basininfil +
     &           Basinsoilmoist - Last_basinsoilmoist +
     &           Basingravstor - Last_basingravstor - Basingw2sz -
     &           Basinszreject + Basinsz2gw + Basinsoiltogw +
     &           Basin_szfarflow*Basin_convert
        IF ( ABS(sz_bal/Basinsoilmoist).GT.ERRCHK )
     &       WRITE (BALUNT, *) 'Possible water balance problem'
        WRITE (BALUNT, 9002) year, mo, day, sz_bal, Basinlakeinsz,
     &                       Basindunnian, Basinslowflow, Basinprefflow,
     &                       Basinpervet, Basininfil, Basinsoilmoist,
     &                       Last_basinsoilmoist, Basingravstor,
     &                       Last_basingravstor, Basingw2sz, Basinsz2gw,
     &                       Basinszreject, Basinsoiltogw,
     &                       Basin_szfarflow*Basin_convert,
     &                       Basinfarfieldflow
      ENDIF

      IF ( Gsf_rpt.EQ.1 ) THEN
        WRITE (Balance_unt, 9001) mo, day, year, Basinppt, Basinpervet,
     &         Basinimpervevap, Basinintcpevap, Basinsnowevap,
     &         Basinstrmflow, Basinsz2gw, Basingw2sz, Gw_inout,
     &         Stream_leakage, Uzf_recharge, Basinseepout, Sat_store,
     &         Unsat_store, Basinsoilmoist, Basingravstor, Basingwstor,
     &         Basinintcpstor, Basinimpervstor, Basinpweqv,
     &         Basininterflow, Basinsroff, Strm_stor, Lake_stor,
     &         Obs_strmflow, Basinszreject, Basinprefstor, Uzf_et,
     &         Uzf_infil, Uzf_del_stor, Net_sz2gw, Sat_change_stor,
     &         Streambed_loss, Sfruz_change_stor, Gwflow2strms,
     &         Sfruz_tot_stor, Lakebed_loss, Lake_change_stor,
     &         Gwflow2lakes, Basininfil, Basindunnian, Basinhortonian,
     &         Basinsm2gvr, Basingvr2sm, Basininfil_tot,
     &         Basininfil2pref, Basindnflow, Basinactet, Basinsnowmelt,
     &         Basinhortonianlakes, Basinlakeinsz, Basinlakeevap,
     &         Basinlakeprecip, Basinfarfieldflow, Basinsoiltogw, KKITER
!     &        basinreachlatflowm3, Basinrain,
!     &        Basinsnow, Basingvr2pfr, Basinslowflow, Basinprefflow
      ENDIF

!     DANGER strmin set to zero
!  RGN I think I fixed strmin
      Cumvol_precip = Cumvol_precip + Basinppt
      Rate_precip = Basinppt
! RGN change Cumvol_strmin to include specified inflows
      Rate_strmin = Stream_inflow
      Cumvol_strmin = Cumvol_strmin + Rate_strmin
      Cumvol_gwbndin = Cumvol_gwbndin + Gw_bnd_in
      Rate_gwbndin = Gw_bnd_in
      Cumvol_wellin = Cumvol_wellin + Well_in
      Rate_wellin = Well_in
      Rate_et = Basinactet
      Cumvol_et = Cumvol_et + Rate_et
      Rate_strmot = Basinstrmflow
      Cumvol_strmot = Cumvol_strmot + Rate_strmot
      Cumvol_gwbndot = Cumvol_gwbndot + Gw_bnd_out
      Rate_gwbndot = Gw_bnd_out
      Cumvol_wellot = Cumvol_wellot + Well_out
      Rate_wellot = Well_out
      IF ( Outflow_flg.EQ.1 ) THEN
        Rate_farout = Basinfarfieldflow
        Cumvol_farout = Cumvol_farout + Rate_farout
      ENDIF
 ! RGN added specified lake inflow/outflow and storage change
      IF ( IUNIT(22).GT.0 ) THEN
        IF ( TOTWTHDRW_LAK.GT.0.0 ) THEN
          Rate_lakot = TOTWTHDRW_LAK
          Cumvol_lakot = Cumvol_lakot + Rate_lakot
        ELSE
          Rate_lakin = TOTWTHDRW_LAK
          Cumvol_lakin = Cumvol_lakin + Rate_lakin
        END IF
        Rate_lakestor = TOTDELSTOR_LAK
        Cum_lakestor = Cum_lakestor + Rate_lakestor
      END IF
      Rate_pweqv = Basinpweqv - Last_basinpweqv
      Cum_pweqv = Cum_pweqv + Rate_pweqv

      Rate_surfstor = Basinintcpstor - Last_basinintcpstor +
     &                Basinimpervstor - Last_basinimpervstor +
     &                Rate_pweqv
      Cum_surfstor = Cum_surfstor + Rate_surfstor

      Rate_soilstor = Basinsoilmoist - Last_basinsoilmoist +
     &                Basingravstor - Last_basingravstor  !grav + pref
      Cum_soilstor = Cum_soilstor + Rate_soilstor

      Rate_uzstor = Uzf_del_stor + Sfruz_change_stor
      Cum_uzstor = Cum_uzstor + Rate_uzstor

      Rate_satstor = Sat_change_stor
      Cum_satstor = Cum_satstor + Rate_satstor

      Rate_delstore = Rate_surfstor + Rate_soilstor + Rate_satstor +
     &                Rate_uzstor + Rate_lakestor + STRMDELSTOR_RATE
      Cum_delstore = Cum_delstore + Rate_delstore + STRMDELSTOR_RATE

      Rpt_count = Rpt_count + 1
      IF ( Rpt_count.EQ.Rpt_days ) THEN  !rpt_days default = 7
        CALL GSFSUMREPORT(year, mo, day, nstep, KKSTP, KKPER)
        Rpt_count = 0
      ENDIF

!  Save old values before computation of new ones
      Last_basinintcpstor = Basinintcpstor
      Last_basinimpervstor = Basinimpervstor
      Last_basinpweqv = Basinpweqv
      Last_basinsoilmoist = Basinsoilmoist
      Last_basingravstor = Basingravstor
      Last_basin_soil_moist = Basin_soil_moist
      Last_basin_ssstor = Basin_ssstor

      gsfsumrun = 0

 9001 FORMAT (2(I2.2, '/'), I4, 55(',', E15.7), ',', I5)
 9002 FORMAT (I5, 2('/', I2.2), F12.3, 16(F12.0))
      END FUNCTION gsfsumrun

!***********************************************************************
!     gsfsumclean - Computes summary values
!***********************************************************************
      INTEGER FUNCTION gsfsumclean()
      USE GSFSUM, ONLY:Balance_unt, Gsf_unt
      IMPLICIT NONE
!***********************************************************************
      gsfsumclean = 1
      CLOSE (Balance_unt)
      CLOSE (Gsf_unt)
      gsfsumclean = 0
      END FUNCTION gsfsumclean

!***********************************************************************
! Print headers for tables
!***********************************************************************
      SUBROUTINE GSF_PRINT()
      USE GSFSUM, ONLY:Balance_unt, Gsf_unt, Csv_output_file, Rpt_days,
     &    Gsflow_output_file, Model_output_file, Gsf_rpt
      USE GSFMODFLOW, ONLY:Logunt
      IMPLICIT NONE
      INCLUDE 'fmodules.inc'
      EXTERNAL GSF_HEADERS
      INTRINSIC CHAR, INDEX
! Local Variables
      LOGICAL :: opend
      INTEGER :: nc
!***********************************************************************
      IF ( control_integer(Gsf_rpt, 'gsf_rpt').NE.0 ) RETURN
      IF ( Gsf_rpt.EQ.1 ) THEN  !gsf_rpt default = 1
        opend = .TRUE.
        Balance_unt = 300
        DO WHILE ( opend )
          Balance_unt = Balance_unt + 1
          INQUIRE (UNIT=Balance_unt, OPENED=opend)
        ENDDO

        IF ( control_string(Csv_output_file, 'csv_output_file').NE.0 )
     &       RETURN
        IF ( Csv_output_file(:1).EQ.' ' .OR.
     &       Csv_output_file(:1).EQ.CHAR(0) )
     &       Csv_output_file = 'gsflow.csv'

        OPEN (UNIT=Balance_unt, FILE=Csv_output_file)
      ENDIF
 
! Open the GSF volumetric balance report file
      opend = .TRUE.
      Gsf_unt = Balance_unt
      DO WHILE ( opend )
        Gsf_unt = Gsf_unt + 1
        INQUIRE (UNIT=Gsf_unt, OPENED=opend)
      ENDDO

      IF ( control_integer(Rpt_days, 'rpt_days').NE.0 ) RETURN
      PRINT *, 'Water Budget print frequency is:', Rpt_days
      WRITE (Logunt, *) 'Water Budget print frequency is:', Rpt_days
      IF ( control_string(Gsflow_output_file, 'gsflow_output_file')
     &     .NE.0 ) RETURN
      IF ( Gsflow_output_file(:1).EQ.' ' .OR.
     &     Gsflow_output_file(:1).EQ.CHAR(0) )
     &     Gsflow_output_file = 'gsflow.out'

      OPEN (UNIT=Gsf_unt, FILE=Gsflow_output_file)
      nc = INDEX(Gsflow_output_file,CHAR(0)) - 1
      IF ( nc.EQ.0 ) nc = 256
      PRINT *, 'Writing GSFLOW Water Budget File: ',
     &         Gsflow_output_file(:nc)
      WRITE (Logunt, *) 'Writing GSFLOW Water Budget File: ',
     &                  Gsflow_output_file(:nc)
      IF ( Gsf_rpt.EQ.1 ) THEN
        nc = INDEX(Csv_output_file,CHAR(0)) - 1
        IF ( nc.EQ.0 ) nc = 256
        PRINT *, 'Writing GSFLOW CSV File: ', Csv_output_file(:nc)
        WRITE (Logunt, *) 'Writing GSFLOW CSV File: ',
     &                    Csv_output_file(:nc)
        CALL GSF_HEADERS()
      ENDIF

      IF ( control_string(Model_output_file, 'model_output_file').NE.0 )
     &     RETURN
      nc = INDEX(Model_output_file,CHAR(0)) - 1
      IF ( nc.EQ.0 ) nc = 256
      PRINT 9001, ' Writing PRMS Water Budget File: ',
     &            Model_output_file(:nc)
      WRITE (Logunt, 9001) ' Writing PRMS Water Budget File: ',
     &                     Model_output_file(:nc)

 9001 FORMAT (A, A, /)
      END SUBROUTINE GSF_PRINT

!***********************************************************************
! Print headers for reports
!***********************************************************************
      SUBROUTINE GSF_HEADERS()
      USE GSFSUM, ONLY:Balance_unt
      IMPLICIT NONE
!***********************************************************************
      ! uzf_tot_stor = unsat_store, modflow_tot_stor = sat_store
      WRITE (Balance_unt, 9001)
 9001 FORMAT ('Date,basinppt,basinpervet,basinimpervevap',
     &        ',basinintcpevap,basinsnowevap,basinstrmflow',
     &        ',basinsz2gw,basingw2sz,gw_inout,stream_leakage',
     &        ',uzf_recharge,basinseepout,sat_stor,unsat_stor',
     &        ',basinsoilmoist,basingravstor,basingwstor',
     &        ',basinintcpstor,basinimpervstor,basinpweqv',
     &        ',basininterflow,basinsroff,strm_stor,lake_stor',
     &        ',obs_strmflow,basinszreject,basinprefstor',
     &        ',uzf_et,uzf_infil,uzf_del_stor,net_sz2gw',
     &        ',sat_change_stor,streambed_loss,sfruz_change_stor',
     &        ',gwflow2strms,sfruz_tot_stor,lakebed_loss',
     &        ',lake_change_stor,gwflow2lakes,basininfil,basindunnian',
     &        ',basinhortonian,basinsm2gvr,basingvr2sm,basininfil_tot',
     &        ',basininfil2pref,basindnflow,basinactet,basinsnowmelt',
     &        ',basinhortonianlakes,basinlakeinsz,basinlakeevap',
     &        ',basinlakeprecip,basinfarfieldflow,basinsoiltogw,kkiter')

      END SUBROUTINE GSF_HEADERS

!***********************************************************************
! Figure out the total basin_gsfstor
!***********************************************************************
      SUBROUTINE BASIN_GET_STORAGE()
      USE GSFSUM
      IMPLICIT NONE
      INCLUDE 'fmodules.inc'
!***********************************************************************

! LAND SURFACE STORAGE
      IF ( getvar('intcp', 'basin_intcp_stor', 1, 'real',
     &     Basin_intcp_stor).NE.0 ) RETURN
      IF ( getvar('srunoff', 'basin_imperv_stor', 1, 'real',
     &     Basin_imperv_stor).NE.0 ) RETURN
      IF ( getvar('snow', 'basin_pweqv', 1, 'real', Basin_pweqv)
     &     .NE.0 ) RETURN

      Basinintcpstor = Basin_intcp_stor*Basin_convert
      Basinimpervstor = Basin_imperv_stor*Basin_convert
      Basinpweqv = Basin_pweqv*Basin_convert

! SOIL STORAGE
      IF ( getvar('soilzone', 'basin_soil_moist', 1, 'real',
     &     Basin_soil_moist).NE.0 ) RETURN
      IF ( getvar('soilzone', 'basin_ssstor', 1, 'real', Basin_ssstor)
     &     .NE.0 ) RETURN
      IF ( getvar('soilzone', 'basin_pref_stor', 1, 'real',
     &     Basin_pref_stor).NE.0 ) RETURN

      Basinsoilmoist = Basin_soil_moist*Basin_convert
      Basingravstor = Basin_ssstor*Basin_convert
      Basinsoilstor = Basingravstor + Basinsoilmoist

! PRMS GW STORAGE
!     IF ( getvar('gwflow', 'basin_gwstor', 1, 'real', Basin_gwstor)
!    &     .NE.0 ) RETURN
!     Basingwstor = Basin_gwstor*Basin_convert

! MODFLOW STORAGE
      IF ( getvar('gsfbud', 'sat_store', 1, 'real', Sat_store)
     &     .NE.0 ) RETURN
      IF ( getvar('gsfbud', 'unsat_store', 1, 'real', Unsat_store)
     &     .NE.0 ) RETURN

      Basin_gsfstor = Sat_store + Unsat_store + Basinsoilmoist +
     &                Basingravstor + Basin_pref_stor + Basinintcpstor +
     &                Basinpweqv + Basinimpervstor + Lake_stor +
     &                Strm_stor

      END SUBROUTINE BASIN_GET_STORAGE

!-------SUBROUTINE GSFSUMREPORT
      SUBROUTINE GSFSUMREPORT(Year, Mo, Day, Nstep, Kkstp, Kkper)
!***********************************************************************
!     PRINTS VOLUMETRIC BUDGET FOR ENTIRE GSFLOW MODEL
!***********************************************************************
      USE GSFSUM
      USE GWFSFRMODULE, ONLY:STRMDELSTOR_RATE, STRMDELSTOR_CUM, IRTFLG
      USE GLOBAL, ONLY:IUNIT
      USE GSFMODFLOW, ONLY:KKITER
      IMPLICIT NONE
      INTRINSIC ABS
      EXTERNAL GSFFMTNUM
! Arguments
      INTEGER :: Kkper, Kkstp, Year, Mo, Day, Nstep
! Local Variables
      REAL :: cumvol_in, cumvol_out, cumdiff, rate_in, rate_out
      REAL :: ratediff, cum_error, rate_error, cum_percent, rate_percent
      CHARACTER(LEN=18) :: text1, text2, text3, text4, text5, text6
      CHARACTER(LEN=18) :: text7, text8, text9, text10, text11, text12
      CHARACTER(LEN=18) :: val1, val2
!***********************************************************************
      text1 = '     PRECIPITATION'
      text2 = '        STREAMFLOW'
      text3 = '  GW BOUNDARY FLOW'
      text4 = '             WELLS'
      text5 = 'EVAPOTRANSPIRATION'
      text6 = '      LAND SURFACE'
      text7 = '         SOIL ZONE'
      text8 = '  UNSATURATED ZONE'
      text9 = '    SATURATED ZONE'
      text10 ='             LAKES'
      text11 ='           STREAMS'
      text12 =' FAR-FIELD OUTFLOW'
      WRITE (Gsf_unt, 9001) Mo, Day, Year, Nstep, Kkper, Kkstp, KKITER
!
!1------PRINT CUMULATIVE VOLUMES AND RATES FOR INFLOW.
      WRITE (Gsf_unt, 9002)
!
!1A-----PRECIPITATION.
      CALL GSFFMTNUM(Cumvol_precip, val1)
      CALL GSFFMTNUM(Rate_precip, val2)
      WRITE (Gsf_unt, 9003) text1, val1, text1, val2
!1B-----STREAMFLOW.
      CALL GSFFMTNUM(Cumvol_strmin, val1)
      CALL GSFFMTNUM(Rate_strmin, val2)
      WRITE (Gsf_unt, 9003) text2, val1, text2, val2
!1C-----GROUND WATER FLOW.
      CALL GSFFMTNUM(Cumvol_gwbndin, val1)
      CALL GSFFMTNUM(Rate_gwbndin, val2)
      WRITE (Gsf_unt, 9003) text3, val1, text3, val2
!1D-----ALL WELLS.
      CALL GSFFMTNUM(Cumvol_wellin, val1)
      CALL GSFFMTNUM(Rate_wellin, val2)
      WRITE (Gsf_unt, 9003) text4, val1, text4, val2
!1E-----LAKES.
      IF ( IUNIT(22).GT.0 ) THEN
        CALL GSFFMTNUM(Cumvol_lakin, val1)
        CALL GSFFMTNUM(Rate_lakin, val2)
        WRITE (Gsf_unt, 9003) text10, val1, text10, val2
      END IF
!
!2------PRINT CUMULATIVE VOLUMES AND RATES FOR OUTFLOW.
      WRITE (Gsf_unt, 9004)
!
!2A-----ALL ET.
      CALL GSFFMTNUM(Cumvol_et, val1)
      CALL GSFFMTNUM(Rate_et, val2)
      WRITE (Gsf_unt, 9003) text5, val1, text5, val2
!2B-----STREAMFLOW.
      CALL GSFFMTNUM(Cumvol_strmot, val1)
      CALL GSFFMTNUM(Rate_strmot, val2)
      WRITE (Gsf_unt, 9003) text2, val1, text2, val2
!2C-----GROUND WATER FLOW.
      CALL GSFFMTNUM(Cumvol_gwbndot, val1)
      CALL GSFFMTNUM(Rate_gwbndot, val2)
      WRITE (Gsf_unt, 9003) text3, val1, text3, val2
!2D-----ALL WELLS.
      CALL GSFFMTNUM(Cumvol_wellot, val1)
      CALL GSFFMTNUM(Rate_wellot, val2)
      WRITE (Gsf_unt, 9003) text4, val1, text4, val2
!2E-----LAKES.
      IF ( IUNIT(22).GT.0 ) THEN
        CALL GSFFMTNUM(Cumvol_lakot, val1)
        CALL GSFFMTNUM(Rate_lakot, val2)
        WRITE (Gsf_unt, 9003) text10, val1, text10, val2
      END IF
!2F-----FAR FIELD
      IF ( Outflow_flg.EQ.1 ) THEN
        CALL GSFFMTNUM(Cumvol_farout, val1)
        CALL GSFFMTNUM(Rate_farout, val2)
        WRITE (Gsf_unt, 9003) text12, val1, text12, val2
      END IF
!
!3------CUMULATIVE INFLOW MINUS CUMULATIVE OUTFLOW.
      cumvol_in = Cumvol_precip + Cumvol_strmin + Cumvol_gwbndin +
     &            Cumvol_wellin + Cumvol_lakin
      cumvol_out = Cumvol_et + Cumvol_strmot + Cumvol_gwbndot +
     &             Cumvol_wellot + Cumvol_lakot + Cumvol_farout
      cumdiff = cumvol_in - cumvol_out
!
!4------INFLOW RATE MINUS OUTFLOW RATE.
      rate_in = Rate_precip + Rate_strmin + Rate_gwbndin + Rate_wellin +
     &          Rate_lakin
      rate_out = Rate_et + Rate_strmot + Rate_gwbndot + Rate_wellot +
     &           Rate_lakot + Rate_farout
      ratediff = rate_in - rate_out
!
!5------PRINT CUMULATIVE AND RATE DIFFERENCES.
      CALL GSFFMTNUM(cumdiff, val1)
      CALL GSFFMTNUM(ratediff, val2)
      WRITE (Gsf_unt, 9005) val1, val2
!
!6-----TOTAL STORAGE CHANGE.
      CALL GSFFMTNUM(Cum_delstore, val1)
      CALL GSFFMTNUM(Rate_delstore, val2)
      WRITE (Gsf_unt, 9006) val1, val2
!
!6A----SURFACE STORAGE CHANGE.
      CALL GSFFMTNUM(Cum_surfstor, val1)
      CALL GSFFMTNUM(Rate_surfstor, val2)
      WRITE (Gsf_unt, 9003) text6, val1, text6, val2
!
!6B----SOIL STORAGE CHANGE.
      CALL GSFFMTNUM(Cum_soilstor, val1)
      CALL GSFFMTNUM(Rate_soilstor, val2)
      WRITE (Gsf_unt, 9003) text7, val1, text7, val2
!
!6C----UNSATURATED ZONE STORAGE CHANGE.
      CALL GSFFMTNUM(Cum_uzstor, val1)
      CALL GSFFMTNUM(Rate_uzstor, val2)
      WRITE (Gsf_unt, 9003) text8, val1, text8, val2
!
!6D----SATURATED ZONE STORAGE CHANGE.
      CALL GSFFMTNUM(Cum_satstor, val1)
      CALL GSFFMTNUM(Rate_satstor, val2)
      WRITE (Gsf_unt, 9003) text9, val1, text9, val2
!
!6E----LAKE STORAGE CHANGE.
      IF ( IUNIT(22).GT.0 ) THEN
        CALL GSFFMTNUM(Cum_lakestor, val1)
        CALL GSFFMTNUM(Rate_lakestor, val2)
        WRITE (Gsf_unt, 9003) text10, val1, text10, val2
      ENDIF
!
!6F----STREAM STORAGE CHANGE.
      IF ( IRTFLG.GT.0 ) THEN
        CALL GSFFMTNUM(STRMDELSTOR_CUM, val1)
        CALL GSFFMTNUM(STRMDELSTOR_RATE, val2)
        WRITE (Gsf_unt, 9003) text11, val1, text11, val2
      END IF
!
!7------PRINT DIFFERENCES AND PERCENT DIFFERENCES BETWEEN IN MINUS
!       OUT AND STORAGE CHANGE.
      cum_error = cumdiff - Cum_delstore
      rate_error = ratediff - Rate_delstore
      CALL GSFFMTNUM(cum_error, val1)
      CALL GSFFMTNUM(rate_error, val2)
      WRITE (Gsf_unt, 9007) val1, val2
      cum_percent = 100.0*(cum_error/
     &              ((cumvol_in+cumvol_out+ABS(Cum_delstore))/2.0))
      rate_percent = 100.0*(rate_error/
     &               ((rate_in+rate_out+ABS(Rate_delstore))/2.0))
      IF ( ABS(cum_percent).GT.5.0 ) WRITE (Gsf_unt, *)
     &      ' ***WARNING, CUMULATIVE VOLUME OFF > 5%'
      IF ( ABS(rate_percent).GT.3.0 ) WRITE (Gsf_unt, *)
     &      ' ***WARNING, FLUX RATES OFF > 3%'
      WRITE (Gsf_unt, 9008) cum_percent, rate_percent

 9001 FORMAT ('1', /, ' SUMMARY VOLUMETRIC BUDGET FOR GSFLOW ', /,
     &        ' DATE:', 2(I3.2), I5.4, 14X, 'CUMULATIVE TIME STEP:', I8,
     &        /, ' MODFLOW STRESS PERIOD', I7, 5X, 'CURRENT TIME STEP:',
     &        I8, 5X, 'ITERATIONS:', I8, //, 1X, 83('-'))
 9002 FORMAT (/, '   CUMULATIVE VOLUMES', 15X, 'L**3', 3X,
     &        'RATES FOR THIS TIME STEP', 11X, 'L**3/T', /, 3X, 18('-'),
     &        22X, 24('-'), //, 37X, 'IN', 41X, 'IN', /, 37X, '--', 41X,
     &        '--')
 9003 FORMAT (3X, A18, ' =', A18, 5X, A18, ' =', A18)
 9004 FORMAT (//, 36X, 'OUT', 40X, 'OUT', /, 36X, '---', 40X, '---') 
 9005 FORMAT (/, 3X, 'INFLOWS - OUTFLOWS =', A18, 5X,
     &        'INFLOWS - OUTFLOWS =', A18, /, 13X, 8('-'), 35X, 8('-'))
 9006 FORMAT (/, 7X, 'STORAGE CHANGE =', A18, 9X, 'STORAGE CHANGE =',
     &        A18, /, 7X, 14('-'), 29X, 14('-'))
 9007 FORMAT (/, ' OVERALL BUDGET ERROR =', A18, 3X,
     &        'OVERALL BUDGET ERROR =', A18, /)
 9008 FORMAT (/, '  PERCENT DISCREPANCY =', F18.2, 3X,
     &        ' PERCENT DISCREPANCY =', F18.2, ///)
!
!8------RETURN.
      END SUBROUTINE GSFSUMREPORT

!-------SUBROUTINE GSFFMTNUM
      SUBROUTINE GSFFMTNUM(Val, Strng)
!     ******************************************************************
!     FORMAT VALUE BASED ON VALUE SIZE
!     ******************************************************************
      USE GSFSUM, ONLY:CLOSEZERO
      IMPLICIT NONE
      INTRINSIC ABS, INT
! Arguments
      REAL, INTENT(IN) :: Val
      CHARACTER(LEN=*), INTENT(OUT) :: Strng
! Local Variables
      REAL, PARAMETER :: BIG = 1.0E07, SMALL = 0.01
      REAL :: absval
!***********************************************************************
      absval = ABS(Val)
      IF ( absval.LT.CLOSEZERO ) THEN
!       WRITE (Strng, '(I18)') INT(Val)
        Strng = ' '
      ELSEIF ( absval.GT.BIG .OR. absval.LT.SMALL ) THEN
        WRITE (Strng, '(1PE18.4)') Val
      ELSE
        WRITE (Strng, '(F18.2)') Val
      ENDIF
      END SUBROUTINE GSFFMTNUM

!***********************************************************************
! Figure out the total storage of the streams
!***********************************************************************
      SUBROUTINE MODFLOW_SFR_GET_STORAGE
      USE GSFSUM, ONLY:Nreach, Strm_stor
      USE GWFSFRMODULE, ONLY:STRM
      IMPLICIT NONE
! Local Variables
      INTEGER :: l
      REAL :: depth, width, strlen
!***********************************************************************
      Strm_stor = 0.0

      DO l = 1, Nreach
        depth = STRM(7, l)
        width = STRM(5, l)
        strlen = STRM(1, l)
        Strm_stor = Strm_stor + (depth*width*strlen)
      ENDDO

      END SUBROUTINE MODFLOW_SFR_GET_STORAGE
