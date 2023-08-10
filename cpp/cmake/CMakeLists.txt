# OS Dependent configurations
if(UNIX)
    if (APPLE)  # MacOS
        add_definitions(-D__MAC__)
        else() # Linux
        add_definitions(-DLINUX -D__GCC__)
        endif()
    add_compile_options(-fPIC -Wno-c++11-narrowing)
else() # Windows
    set(WINDOWS_EXPORT_ALL_SYMBOLS ON)
    add_definitions(-DWIN32 -D_WINDOWS -D_USRDLL -D_CRT_SECURE_NO_WARNINGS -DNON_UNIX_STDIO -D__VC__ -DALPHA__LIB__)
    #set(CMAKE_EXE_LINKER_FLAGS ../src/lib/raddll.def)
endif()

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 11)

message(STATUS "Compiler is: ${CMAKE_C_COMPILER} | ${CMAKE_CXX_COMPILER}")

if(USE_MPI)
    find_package(MPI REQUIRED)
    message(STATUS "MPI location: ${MPI_CXX_LIBRARIES} | Include: ${MPI_CXX_INCLUDE_DIRS}")
    message(STATUS "OpenMP Flags: C -> ${MPI_C_LINK_FLAGS} | CXX -> ${MPI_CXX_LINK_FLAGS}")
    set(RADIA_DEFINITIONS -DFFTW_ENABLE_FLOAT -DNO_TIMER -DANSI_DECLARATORS -DTRILIBRARY -D_GM_WITHOUT_BASE -D_WITH_MPI)

    # Setup OpenMP as a linked library for all targets
    link_libraries(MPI::MPI_CXX)
    # Setup OpenMP include dir for all targets
    include_directories(${MPI_CXX_INCLUDE_DIRS})
else()
    set(RADIA_DEFINITIONS -DFFTW_ENABLE_FLOAT -DNO_TIMER -DANSI_DECLARATORS -DTRILIBRARY -D_GM_WITHOUT_BASE)
endif()

# Setup definitions for all targets
add_definitions(${RADIA_DEFINITIONS})

#ext
#auxparse
set(auxparse_source_files
    ../src/ext/auxparse/auxparse.cpp
    ../src/ext/auxparse/auxparse.h
)

add_library(auxparse OBJECT ${auxparse_source_files})
target_include_directories(auxparse PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/../src/ext/auxparse)
target_compile_definitions(auxparse PRIVATE ${RADIA_DEFINITIONS})

#genmath
set(genmath_source_files
    ../src/ext/genmath/gmfft.cpp
    ../src/ext/genmath/gmfft.h
    ../src/ext/genmath/gmfit.cpp
    ../src/ext/genmath/gmfit.h
    ../src/ext/genmath/gminterp.cpp
    ../src/ext/genmath/gminterp.h
    ../src/ext/genmath/gmmeth.cpp
    ../src/ext/genmath/gmmeth.h
    ../src/ext/genmath/gmtrans.cpp
    ../src/ext/genmath/gmtrans.h
    ../src/ext/genmath/gmvbstr.h
)

add_library(genmath OBJECT ${genmath_source_files})
target_link_libraries(genmath PUBLIC auxparse)
target_include_directories(genmath PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/../src/ext/genmath/ ${CMAKE_CURRENT_SOURCE_DIR}/../src/lib)

if(USE_MPI)
    target_include_directories(genmath PUBLIC ${MPI_CXX_INCLUDE_DIRS})
endif()

target_compile_definitions(genmath PRIVATE ${RADIA_DEFINITIONS})

#triangle
set(triangle_source_files
    ../src/ext/triangle/triangle.c
)

add_library(triangle OBJECT ${triangle_source_files})
target_include_directories(triangle PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/../src/ext/triangle/)
target_compile_definitions(triangle PRIVATE ${RADIA_DEFINITIONS})

#core
set(core_source_files
    ../src/core/radapl1.cpp
    ../src/core/radapl2.cpp
    ../src/core/radapl3.cpp
    ../src/core/radapl4.cpp
    ../src/core/radapl5.cpp
    ../src/core/radapl6.cpp
    ../src/core/radapl7.cpp
    ../src/core/radarccu.cpp
    ../src/core/radcast.cpp
    ../src/core/radexpgn.cpp
    ../src/core/radflm.cpp
    ../src/core/radg3d.cpp
    ../src/core/radg3dgr.cpp
    ../src/core/radgroup.cpp
    ../src/core/radinter.cpp
    ../src/core/radintrc.cpp
    ../src/core/radiobuf.cpp
    ../src/core/radmamet.cpp
    ../src/core/radmater.cpp
    ../src/core/radplnr1.cpp
    ../src/core/radplnr2.cpp
    ../src/core/radptrj.cpp
    ../src/core/radrec.cpp
    ../src/core/radrlmet.cpp
    ../src/core/radsbdac.cpp
    ../src/core/radsbdep.cpp
    ../src/core/radsbdrc.cpp
    ../src/core/radsbdvp.cpp
    ../src/core/radsend.cpp
    ../src/core/radvlpgn.cpp
)

add_library(core OBJECT ${core_source_files})
target_link_libraries(core genmath triangle)
target_compile_definitions(core PRIVATE ${RADIA_DEFINITIONS})

target_include_directories(core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/../src/core)
target_include_directories(core PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../src/lib>
)

#lib
set(radia_lib_source_files
    ../src/lib/radentry.cpp
    ../src/lib/radentry.h
)

add_library(radia STATIC
    ${radia_lib_source_files}
    $<TARGET_OBJECTS:core>
    $<TARGET_OBJECTS:genmath>
    $<TARGET_OBJECTS:triangle>
    $<TARGET_OBJECTS:auxparse>
)


# Add definitions needed to build Radia
target_compile_definitions(radia PUBLIC ${RADIA_DEFINITIONS})

# Libraries in which Radia lib depends
target_link_libraries(radia core ${FFTW_DOUBLE_LIB} ${FFTW_FLOAT_LIB})

if (UNIX)
    # Math library is only needed by unix. When using Windows, VS does it for you.
    target_link_libraries(radia m)
endif()

target_include_directories(radia PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../src/lib>
)
target_include_directories(radia PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../src/core>
)
target_include_directories(radia PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../src/ext/auxparse>
)
target_include_directories(radia PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../src/ext/triangle>
)
target_include_directories(radia PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../src/ext/genmath>
)

install(TARGETS radia LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})

# clients
# c
set(radia_clients_c_source_files
    ../src/clients/c/radclient.cpp
)

add_library(radiaclient ${radia_clients_c_source_files})

target_link_libraries(radiaclient radia)

target_include_directories(radiaclient PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../src/clients/c/>
)

install(TARGETS radiaclient RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

# python
# for testing we will need the python interpreter
find_package(PythonInterp REQUIRED)

# we require python development headers
find_package(PythonLibs ${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR} EXACT REQUIRED)


set(radia_clients_python_source_files
    ../src/clients/python/radpy.cpp
)

add_library(radiapy SHARED ${radia_clients_python_source_files})

target_include_directories(radiapy PUBLIC ${PYTHON_INCLUDE_DIRS})

target_include_directories(radiapy PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../src/clients/python>)

# prevent cmake from creating a "lib" prefix
set_target_properties(radiapy PROPERTIES PREFIX "")

if (UNIX)
    # Math library is only needed by unix. When using Windows, VS does it for you.
    target_link_libraries(radiapy m ${FFTW_DOUBLE_LIB} ${FFTW_FLOAT_LIB} radia)

    set_target_properties(radiapy PROPERTIES SUFFIX ".so")

    # The -shared flag is only valid for UNIX systems.
    set_target_properties(radiapy PROPERTIES LINK_FLAGS "-shared")
endif()

if(APPLE)
    # We need the undefined dynamic_lookup to overcome issues with a statically linked
    # python. More details here: https://gitlab.kitware.com/vtk/vtk/-/issues/17214
    set_target_properties(radiapy PROPERTIES LINK_FLAGS "-undefined dynamic_lookup -shared")
endif()

if(WIN32)
  target_link_libraries(radiapy radia ${PYTHON_LIBRARIES})
  set_target_properties(radiapy PROPERTIES SUFFIX ".pyd")
endif()

add_custom_command(TARGET radiapy POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:radiapy> ${CMAKE_SOURCE_DIR}/env/python/radia/
)

#install(TARGETS radiapy LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})