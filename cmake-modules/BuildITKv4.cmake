macro(patch_itk_config file to_remove)
  file(READ "${file}" config_file)
  STRING(REPLACE "${to_remove}//" "/" config_file "${config_file}")
  STRING(REPLACE "${to_remove}" "" config_file "${config_file}")
  message("patched ${file} ")
  file(WRITE "${file}" "${config_file}")
endmacro(patch_itk_config)


macro(build_itkv4 install_prefix staging_prefix minc_dir hdf_bin_dir hdf_include_dir hdf_library_dir zlib_include_dir zlib_library)
  find_package(Threads REQUIRED)

  if(CMAKE_EXTRA_GENERATOR)
    set(CMAKE_GEN "${CMAKE_EXTRA_GENERATOR} - ${CMAKE_GENERATOR}")
  else()
    set(CMAKE_GEN "${CMAKE_GENERATOR}")
  endif()
  
  set(CMAKE_OSX_EXTERNAL_PROJECT_ARGS)
  if(APPLE)
    SET(ITK_CXX_COMPILER "${CMAKE_CXX_COMPILER}" CACHE FILEPATH "C++ Compiler for ITK")
    SET(ITK_C_COMPILER "${CMAKE_C_COMPILER}" CACHE FILEPATH "C Compiler for ITK")
    list(APPEND CMAKE_OSX_EXTERNAL_PROJECT_ARGS
      -DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES}
      -DCMAKE_OSX_SYSROOT=${CMAKE_OSX_SYSROOT}
      -DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}
      -DCMAKE_C_COMPILER:FILEPATH=${ITK_C_COMPILER}
      -DCMAKE_CXX_COMPILER:FILEPATH=${ITK_CXX_COMPILER}
    )
  endif()
	
  SET(HDF5_LIB_SUFFIX ".a")
  
  if(MT_BUILD_SHARED_LIBS) 
    SET(ITK_SHARED_LIBRARY "ON")
    
    IF(MT_BUILD_SHARED_LIBS)
      IF(APPLE)
        SET(HDF5_LIB_SUFFIX ".dylib")
      ELSE(APPLE)
        SET(HDF5_LIB_SUFFIX ".so")
      ENDIF(APPLE)
    ENDIF(MT_BUILD_SHARED_LIBS)
    
    
  else(MT_BUILD_SHARED_LIBS) 
    SET(ITK_SHARED_LIBRARY "OFF")
  endif(MT_BUILD_SHARED_LIBS) 

  ExternalProject_Add(ITKv4
    #GIT_REPOSITORY "http://itk.org/ITK.git"
    #GIT_TAG "421d314ff85ad542ad5c0f3d3c115fa7427b1c64"
    URL  "http://downloads.sourceforge.net/project/itk/itk/4.5/InsightToolkit-4.5.1.tar.gz"
    URL_MD5 "a174fd50a5bc986f0944903cfceb3e9b"
    UPDATE_COMMAND ""
    SOURCE_DIR ITKv4
    BINARY_DIR ITKv4-build
    CMAKE_GENERATOR ${CMAKE_GEN}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
        -DBUILD_SHARED_LIBS:BOOL=${ITK_SHARED_LIBRARY}
        -DCMAKE_SKIP_RPATH:BOOL=YES
        -DCMAKE_INSTALL_PREFIX:PATH=${install_prefix}
        -DCMAKE_CXX_FLAGS:STRING=${CMAKE_CXX_FLAGS}
        -DCMAKE_C_FLAGS:STRING=${CMAKE_C_FLAGS}
        -DCMAKE_EXE_LINKER_FLAGS:STRING=${CMAKE_EXE_LINKER_FLAGS}
        -DCMAKE_MODULE_LINKER_FLAGS:STRING=${CMAKE_MODULE_LINKER_FLAGS}
        -DCMAKE_SHARED_LINKER_FLAGS:STRING=${CMAKE_SHARED_LINKER_FLAGS}
        ${CMAKE_OSX_EXTERNAL_PROJECT_ARGS}
        -DBUILD_EXAMPLES:BOOL=OFF
        -DBUILD_TESTING:BOOL=OFF
        -DITK_USE_REVIEW:BOOL=ON
        -DModule_ITKIOMINC:BOOL=ON
        -DITK_USE_SYSTEM_MINC:BOOL=ON
        -DITK_USE_SYSTEM_HDF5:BOOL=ON
        -DITK_USE_SYSTEM_ZLIB:BOOL=ON
        -DLIBMINC_DIR:PATH=${minc_dir}
        -DHDF5_CXX_COMPILER_EXECUTABLE:FILEPATH=${hdf_bin_dir}/h5c++
        -DHDF5_C_COMPILER_EXECUTABLE:FILEPATH=${hdf_bin_dir}/h5cc
        -DHDF5_CXX_LIBRARY:PATH=${hdf_library_dir}/libhdf5_cpp${HDF5_LIB_SUFFIX}
        -DHDF5_C_LIBRARY:PATH=${hdf_library_dir}/libhdf5${HDF5_LIB_SUFFIX}
        -DHDF5_DIFF_EXECUTABLE:FILEPATH=${hdf_bin_dir}/h5diff
        -DHDF5_CXX_INCLUDE_DIR:PATH=${hdf_include_dir}
        -DHDF5_C_INCLUDE_DIR:PATH=${hdf_include_dir}
        -DHDF5_hdf5_LIBRARY:FILEPATH=${hdf_library_dir}/libhdf5${HDF5_LIB_SUFFIX}
        -DHDF5_hdf5_cpp_LIBRARY:FILEPATH=${hdf_library_dir}/libhdf5_cpp${HDF5_LIB_SUFFIX}
        -DHDF5_hdf5_LIBRARY_RELEASE:FILEPATH=${hdf_library_dir}/libhdf5${HDF5_LIB_SUFFIX}
        -DHDF5_hdf5_cpp_LIBRARY_RELEASE:FILEPATH=${hdf_library_dir}/libhdf5_cpp${HDF5_LIB_SUFFIX}
#        -DHDF5_DIR:PATH=/home/vfonov/src/build/minc-toolkit-itk4/HDF5-build
        -DHDF5_Fortran_COMPILER_EXECUTABLE:FILEPATH=''
        -DZLIB_LIBRARY:PATH=${zlib_library}
        -DZLIB_INCLUDE_DIR:PATH=${zlib_include_dir}
        -DITK_LEGACY_REMOVE:BOOL=OFF
    INSTALL_COMMAND make install DESTDIR=${staging_prefix}
    INSTALL_DIR ${staging_prefix}/${install_prefix}
  )
  #FORCE_BUILD_CHECK(ITKv4  )
  #SET(ITK_DIR ${CMAKE_CURRENT_BINARY_DIR}/ITKv4-build)
  #SET(ITK_USE_FILE  ${CMAKE_CURRENT_BINARY_DIR}/ITKv4-build/UseITK.cmake)
  #SET(ITK_FOUND ON)
  
  # let's patch targets to remove staging directory
  FOREACH(conf "ITKTargets-release.cmake" "Modules/ITKZLIB.cmake" "Modules/ITKZLIB.cmake" "Modules/ITKMINC.cmake" "Modules/ITKHDF5.cmake")
    patch_itk_config("${staging_prefix}/${install_prefix}/lib/cmake/ITK-4.5/${conf}" "${staging_prefix}")
  ENDFOREACH(conf)
  
  # a hack to remove internal minc directories
  file(READ "${staging_prefix}/${install_prefix}/lib/cmake/ITK-4.5/Modules/ITKMINC.cmake" config_file)
  STRING(REPLACE ";${minc_dir}/ezminc" "" config_file "${config_file}")
  STRING(REPLACE "${CMAKE_CURRENT_BINARY_DIR}/ITKv4-build/Modules/ThirdParty/MINC/src;" "" config_file "${config_file}")
  STRING(REPLACE "${minc_dir}" "${install_prefix}/lib" config_file "${config_file}")
  STRING(REPLACE "${LIBMINC_INCLUDE_DIRS}" "${install_prefix}/include" config_file "${config_file}")
  file(WRITE "${staging_prefix}/${install_prefix}/lib/cmake/ITK-4.5/Modules/ITKMINC.cmake" "${config_file}")
  
  
  SET(ITK_DIR ${CMAKE_CURRENT_BINARY_DIR}/ITKv4-build)
  
  SET(ITK_INCLUDE_DIRS 
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4-build
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4/Code/Algorithms
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4/Code/BasicFilters
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4/Code/Common
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4/Code/Numerics
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4/Code/IO
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4/Code/Numerics/FEM
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4/Code/Numerics/NeuralNetworks
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4/Code/SpatialObject
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4/Utilities/MetaIO
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4/Utilities/NrrdIO
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4-build/Utilities/NrrdIO
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4/Utilities/DICOMParser
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4-build/Utilities/DICOMParser
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4-build/Utilities/expat
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4/Utilities/expat
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4/Utilities/nifti/niftilib
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4/Utilities/nifti/znzlib
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4/Utilities/itkExtHdrs
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4-build/Utilities
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4/Utilities
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4/Utilities/vxl/v3p/netlib
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4/Utilities/vxl/vcl
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4/Utilities/vxl/core
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4-build/Utilities/vxl/v3p/netlib
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4-build/Utilities/vxl/vcl
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4-build/Utilities/vxl/core
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4-build/Utilities/gdcm
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4/Utilities/gdcm/src
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4/Code/Review
        ${CMAKE_CURRENT_BINARY_DIR}/ITKv4/Code/Review/Statistics)

# The ITK library directories.
  SET(ITK_LIBRARY_DIRS "${CMAKE_CURRENT_BINARY_DIR}/ITKv4-build/bin")
  
  SET(ITK_LIBRARIES  
          ITKAlgorithms ITKStatistics 
          ITKNumerics 
          ITKFEM ITKQuadEdgeMesh 
          ITKBasicFilters  ITKIO ITKNrrdIO 
          ITKSpatialObject ITKMetaIO
          ITKDICOMParser ITKEXPAT
          ITKniftiio ITKTransformIOReview  ITKCommon ITKznz 
          itkgdcm itkpng itktiff itkzlib itkvcl 
          itkvcl 
          itkv3p_lsqr  itkvnl_algo itkvnl_inst itkvnl itkv3p_netlib 
          itksys itkjpeg8 itkjpeg12 itkjpeg16 itkopenjpeg  hdf5_cpp hdf5
          ${CMAKE_THREAD_LIBS_INIT}
          )

  IF(UNIX)
    SET(ITK_LIBRARIES  ${ITK_LIBRARIES} dl)
  ENDIF(UNIX)

endmacro(build_itkv4)