cmake_minimum_required(VERSION 3.31)
project(jappeos_installerd)

set(CMAKE_CXX_STANDARD 20)

include(GNUInstallDirs)
find_package(PkgConfig REQUIRED)

pkg_check_modules(UDEV REQUIRED libudev)
pkg_check_modules(PARTED REQUIRED libparted)

include(FetchContent)
FetchContent_Declare(
        jappeos_daemon_core
        GIT_REPOSITORY https://github.com/JappeOS/jappeos_daemon_core.git
        GIT_TAG main-v1.1.4-1
)
FetchContent_MakeAvailable(jappeos_daemon_core)

set(JAPPEOS_INSTALLERD_SOURCES
        src/main.cpp
        src/steps/cleanup_step.cpp
        src/steps/cleanup_step.h
        src/steps/configure_system_step.cpp
        src/steps/configure_system_step.h
        src/steps/format_step.cpp
        src/steps/format_step.h
        src/steps/generate_fstab_step.cpp
        src/steps/generate_fstab_step.h
        src/steps/install_bootloader_step.cpp
        src/steps/install_bootloader_step.h
        src/steps/install_dummy_step.cpp
        src/steps/install_dummy_step.h
        src/steps/install_rootfs_step.cpp
        src/steps/install_rootfs_step.h
        src/steps/mount_step.cpp
        src/steps/mount_step.h
        src/steps/partition_step.cpp
        src/steps/partition_step.h
        src/steps/validate_install_step.cpp
        src/steps/validate_install_step.h
        src/install_controller.cpp
        src/install_controller.h
        src/install_data.h
        src/install_state.h
        src/install_step.h
        src/install_storage_data_builder.cpp
        src/install_storage_data_builder.h
        src/installer_def.h
        src/installer_service.cpp
        src/installer_service.h
)

function(jappeos_configure_target target_name)
    target_include_directories(${target_name} PRIVATE
            ${UDEV_INCLUDE_DIRS}
            ${PARTED_INCLUDE_DIRS}
    )

    target_compile_options(${target_name} PRIVATE
            -march=x86-64
            -mtune=generic
            -fno-lto
            -mno-avx
            -mno-avx2
            -mno-fma
            -mno-bmi
            -mno-bmi2
            -mno-sse4.1
            -mno-sse4.2
            $<$<CONFIG:Debug>:-O0 -g>
            $<$<CONFIG:Release>:-O2 -g -fno-omit-frame-pointer>
            ${UDEV_CFLAGS_OTHER}
            ${PARTED_CFLAGS_OTHER}
    )

    target_link_options(${target_name} PRIVATE
            $<$<CONFIG:Debug>:-rdynamic>
    )

    target_link_libraries(${target_name} PRIVATE
            ${UDEV_LIBRARIES}
            ${PARTED_LIBRARIES}
            jappeos_daemon_core::jappeos_daemon_core
    )

    set_target_properties(${target_name} PROPERTIES
            INSTALL_RPATH "$ORIGIN"
            BUILD_WITH_INSTALL_RPATH TRUE
    )
endfunction()

add_executable(jappeos_installerd
        ${JAPPEOS_INSTALLERD_SOURCES}
)
jappeos_configure_target(jappeos_installerd)

install(TARGETS jappeos_installerd
        RUNTIME DESTINATION "${CMAKE_INSTALL_LIBDIR}/jappeos_installerd"
)

install(DIRECTORY ../data/dbus-1/interfaces/
        DESTINATION "${CMAKE_INSTALL_DATADIR}/dbus-1/interfaces"
        FILES_MATCHING PATTERN "*.xml"
)

install(DIRECTORY ../data/dbus-1/system-services/
        DESTINATION "${CMAKE_INSTALL_DATADIR}/dbus-1/system-services"
        FILES_MATCHING PATTERN "*.service"
)

install(DIRECTORY ../data/dbus-1/system.d/
        DESTINATION "${CMAKE_INSTALL_DATADIR}/dbus-1/system.d"
        FILES_MATCHING PATTERN "*.conf"
)

install(DIRECTORY ../data/systemd/system/
        DESTINATION "${CMAKE_INSTALL_LIBDIR}/systemd/system"
        FILES_MATCHING PATTERN "*.service"
)