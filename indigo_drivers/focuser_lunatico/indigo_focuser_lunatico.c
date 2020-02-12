// Copyright (C) 2020 Rumen G. Bogdanovski
// All rights reserved.
//
// You can use this software under the terms of 'INDIGO Astronomy
// open-source license' (see LICENSE.md).
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHORS 'AS IS' AND ANY EXPRESS
// OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// version history
// 2.0 by Rumen G. Bogdanovski

/** INDIGO Lunatico Armadillo/Platipus focuser driver
 \file indigo_focuser_lunatico.c
 */

#define DRIVER_VERSION 0x0001
//#define DRIVER_NAME    "indigo_focuser_lunatico"

#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <math.h>
#include <assert.h>
#include <errno.h>
#include <pthread.h>
#include <stdbool.h>
#include <sys/time.h>

#if defined(INDIGO_FREEBSD)
#include <libusb.h>
#else
#include <libusb-1.0/libusb.h>
#endif

#include <indigo/indigo_driver_xml.h>

#include <indigo/indigo_io.h>

#include "indigo_focuser_lunatico.h"

#define DSD_AF1_AF2_BAUDRATE            "9600"
#define DSD_AF3_BAUDRATE                "115200"

#define PRIVATE_DATA                    ((lunatico_private_data *)device->private_data)
#define DEVICE_DATA                     ((lunatico_device_data *)PRIVATE_DATA->shared_data)

#define LA_MODEL_HINT_PROPERTY          (PRIVATE_DATA->model_hint_property)
#define LA_MODEL_AUTO_ITEM              (LA_MODEL_HINT_PROPERTY->items+0)
#define LA_MODEL_ARMADILLO_ITEM         (LA_MODEL_HINT_PROPERTY->items+1)
#define LA_MODEL_PLATIPUS_ITEM          (LA_MODEL_HINT_PROPERTY->items+2)

#define LA_MODEL_HINT_PROPERTY_NAME     "LUNATICO_MODEL_HINT"
#define LA_MODEL_AUTO_ITEM_NAME         "AUTO_DETECT"
#define LA_MODEL_ARMADILLO_ITEM_NAME    "ARMADILLO"
#define LA_MODEL_PLATIPUS_ITEM_NAME     "PLATIPUS"


#define DSD_STEP_MODE_PROPERTY          (PRIVATE_DATA->step_mode_property)
#define DSD_STEP_MODE_FULL_ITEM         (DSD_STEP_MODE_PROPERTY->items+0)
#define DSD_STEP_MODE_HALF_ITEM         (DSD_STEP_MODE_PROPERTY->items+1)
#define DSD_STEP_MODE_FOURTH_ITEM       (DSD_STEP_MODE_PROPERTY->items+2)
#define DSD_STEP_MODE_EIGTH_ITEM        (DSD_STEP_MODE_PROPERTY->items+3)
#define DSD_STEP_MODE_16TH_ITEM         (DSD_STEP_MODE_PROPERTY->items+4)
#define DSD_STEP_MODE_32TH_ITEM         (DSD_STEP_MODE_PROPERTY->items+5)
#define DSD_STEP_MODE_64TH_ITEM         (DSD_STEP_MODE_PROPERTY->items+6)
#define DSD_STEP_MODE_128TH_ITEM        (DSD_STEP_MODE_PROPERTY->items+7)
#define DSD_STEP_MODE_256TH_ITEM        (DSD_STEP_MODE_PROPERTY->items+8)

#define DSD_STEP_MODE_PROPERTY_NAME     "DSD_STEP_MODE"
#define DSD_STEP_MODE_FULL_ITEM_NAME    "FULL"
#define DSD_STEP_MODE_HALF_ITEM_NAME    "HALF"
#define DSD_STEP_MODE_FOURTH_ITEM_NAME  "FOURTH"
#define DSD_STEP_MODE_EIGTH_ITEM_NAME   "EIGTH"
#define DSD_STEP_MODE_16TH_ITEM_NAME    "16TH"
#define DSD_STEP_MODE_32TH_ITEM_NAME    "32TH"
#define DSD_STEP_MODE_64TH_ITEM_NAME    "64TH"
#define DSD_STEP_MODE_128TH_ITEM_NAME   "128TH"
#define DSD_STEP_MODE_256TH_ITEM_NAME   "256TH"

#define DSD_COILS_MODE_PROPERTY              (PRIVATE_DATA->coils_mode_property)
#define DSD_COILS_MODE_IDLE_OFF_ITEM         (DSD_COILS_MODE_PROPERTY->items+0)
#define DSD_COILS_MODE_ALWAYS_ON_ITEM        (DSD_COILS_MODE_PROPERTY->items+1)
#define DSD_COILS_MODE_TIMEOUT_ITEM          (DSD_COILS_MODE_PROPERTY->items+2)

#define DSD_COILS_MODE_PROPERTY_NAME         "DSD_COILS_MODE"
#define DSD_COILS_MODE_IDLE_OFF_ITEM_NAME    "OFF_WHEN_IDLE"
#define DSD_COILS_MODE_ALWAYS_ON_ITEM_NAME   "ALWAYS_ON"
#define DSD_COILS_MODE_TIMEOUT_ITEM_NAME     "TIMEOUT_OFF"

#define DSD_CURRENT_CONTROL_PROPERTY         (PRIVATE_DATA->current_control_property)
#define DSD_CURRENT_CONTROL_MOVE_ITEM        (DSD_CURRENT_CONTROL_PROPERTY->items+0)
#define DSD_CURRENT_CONTROL_HOLD_ITEM        (DSD_CURRENT_CONTROL_PROPERTY->items+1)

#define DSD_CURRENT_CONTROL_PROPERTY_NAME    "DSD_CURRENT_CONTROL"
#define DSD_CURRENT_CONTROL_MOVE_ITEM_NAME   "MOVE_CURRENT"
#define DSD_CURRENT_CONTROL_HOLD_ITEM_NAME   "HOLD_CURRENT"

#define DSD_TIMINGS_PROPERTY                 (PRIVATE_DATA->timings_property)
#define DSD_TIMINGS_SETTLE_ITEM              (DSD_TIMINGS_PROPERTY->items+0)
#define DSD_TIMINGS_COILS_TOUT_ITEM            (DSD_TIMINGS_PROPERTY->items+1)

#define DSD_TIMINGS_PROPERTY_NAME            "DSD_TIMINGS"
#define DSD_TIMINGS_SETTLE_ITEM_NAME         "SETTLE_TIME"
#define DSD_TIMINGS_COILS_TOUT_ITEM_NAME     "COILS_POWER_TIMEOUT"


// gp_bits is used as boolean
#define is_connected                    gp_bits
#define MAX_PORTS  3
#define MAX_DEVICES 4


typedef struct {
	int port_index;
	int focuser_version;
	int current_position, target_position, max_position, backlash;
	double prev_temp;
	void *shared_data;
	indigo_timer *focuser_timer, *temperature_timer;
	pthread_mutex_t port_mutex;
	indigo_property *step_mode_property, *coils_mode_property, *current_control_property, *timings_property, *model_hint_property;
} lunatico_private_data;

typedef struct {
	int handle;
	int count_open;
	int device_index;
	indigo_device *port[MAX_PORTS];
	lunatico_private_data *private_data[MAX_PORTS];
	pthread_mutex_t port_mutex;
} lunatico_device_data;

static void compensate_focus(indigo_device *device, double new_temp);

static lunatico_device_data device_data[MAX_DEVICES] = {0};

static void create_device(int device_index, int port_index, char *name_ext);
static void delete_device(int device_index, int port_index);

/* Deepsky Dad Commands ======================================================================== */

#define DSD_CMD_LEN 100

typedef enum {
	COILS_MODE_IDLE_OFF = 0,
	COILS_MODE_ALWAYS_ON = 1,
	COILS_MODE_IDLE_TIMEOUT = 2
} coilsmode_t;

typedef enum {
	STEP_MODE_FULL = 1,
	STEP_MODE_HALF = 2,
	STEP_MODE_FOURTH = 4,
	STEP_MODE_EIGTH = 8,
	STEP_MODE_16TH = 16,
	STEP_MODE_32TH = 32,
	STEP_MODE_64TH = 64,
	STEP_MODE_128TH = 128,
	STEP_MODE_256TH = 256
} stepmode_t;

#define NO_TEMP_READING                (-127)

static bool dsd_command(indigo_device *device, const char *command, char *response, int max, int sleep) {
	char c;
	struct timeval tv;
	pthread_mutex_lock(&DEVICE_DATA->port_mutex);
	// flush
	while (true) {
		fd_set readout;
		FD_ZERO(&readout);
		FD_SET(DEVICE_DATA->handle, &readout);
		tv.tv_sec = 0;
		tv.tv_usec = 100000;
		long result = select(DEVICE_DATA->handle+1, &readout, NULL, NULL, &tv);
		if (result == 0)
			break;
		if (result < 0) {
			pthread_mutex_unlock(&DEVICE_DATA->port_mutex);
			return false;
		}
		result = read(DEVICE_DATA->handle, &c, 1);
		if (result < 1) {
			pthread_mutex_unlock(&DEVICE_DATA->port_mutex);
			return false;
		}
	}
	// write command
	indigo_write(DEVICE_DATA->handle, command, strlen(command));
	if (sleep > 0)
		usleep(sleep);

	// read responce
	if (response != NULL) {
		int index = 0;
		int timeout = 3;
		while (index < max) {
			fd_set readout;
			FD_ZERO(&readout);
			FD_SET(DEVICE_DATA->handle, &readout);
			tv.tv_sec = timeout;
			tv.tv_usec = 100000;
			timeout = 0;
			long result = select(DEVICE_DATA->handle+1, &readout, NULL, NULL, &tv);
			if (result <= 0)
				break;
			result = read(DEVICE_DATA->handle, &c, 1);
			if (result < 1) {
				pthread_mutex_unlock(&DEVICE_DATA->port_mutex);
				INDIGO_DRIVER_ERROR(DRIVER_NAME, "Failed to read from %s -> %s (%d)", DEVICE_PORT_ITEM->text.value, strerror(errno), errno);
				return false;
			}
			response[index++] = c;

			if (c == ')')
				break;
		}
		response[index] = 0;
	}
	pthread_mutex_unlock(&DEVICE_DATA->port_mutex);
	INDIGO_DRIVER_DEBUG(DRIVER_NAME, "Command %s -> %s", command, response != NULL ? response : "NULL");
	return true;
}


static bool dsd_get_info(indigo_device *device, char *board, char *firmware) {
	if(!board || !firmware) return false;

	char response[DSD_CMD_LEN]={0};
	if (dsd_command(device, "[GFRM]", response, sizeof(response), 100)) {
		int parsed = sscanf(response, "(Board=%[^','], Version=%[^')'])", board, firmware);
		if (parsed != 2) return false;
		INDIGO_DRIVER_DEBUG(DRIVER_NAME, "[GFRM] -> %s = %s %s", response, board, firmware);
		return true;
	}
	INDIGO_DRIVER_ERROR(DRIVER_NAME, "NO response");
	return false;
}


static bool dsd_command_get_value(indigo_device *device, const char *command, uint32_t *value) {
	if (!value) return false;

	char response[DSD_CMD_LEN]={0};
	if (dsd_command(device, command, response, sizeof(response), 100)) {
		int parsed = sscanf(response, "(%d)", value);
		if (parsed != 1) return false;
		INDIGO_DRIVER_DEBUG(DRIVER_NAME, "%s -> %s = %d", command, response, *value);
		return true;
	}
	INDIGO_DRIVER_ERROR(DRIVER_NAME, "NO response");
	return false;
}


static bool dsd_command_set_value(indigo_device *device, const char *command, uint32_t value) {
	char command_string[DSD_CMD_LEN];
	char response[DSD_CMD_LEN];

	snprintf(command_string, DSD_CMD_LEN, command, value);
	if(!dsd_command(device, command_string, response, sizeof(response), 100)) return false;

	if(strcmp(response, "(OK)") == 0) {
		return true;
	}
	return false;
}


static bool dsd_stop(indigo_device *device) {
	return dsd_command(device, "[STOP]", NULL, 0, 100);
}


static bool dsd_sync_position(indigo_device *device, uint32_t pos) {
	return dsd_command_set_value(device, "[SPOS%06d]", pos);
}


static bool dsd_set_reverse(indigo_device *device, bool enabled) {
	char command[DSD_CMD_LEN];
	char response[DSD_CMD_LEN];

	snprintf(command, DSD_CMD_LEN, "[SREV%01d]", enabled ? 1 : 0);
	if(!dsd_command(device, command, response, sizeof(response), 100)) return false;

	if(strcmp(response, "(OK)") == 0) {
		return true;
	}
	return false;
}


static bool dsd_get_position(indigo_device *device, uint32_t *pos) {
	return dsd_command_get_value(device, "[GPOS]", pos);
}


static bool dsd_goto_position(indigo_device *device, uint32_t position) {
	char command[DSD_CMD_LEN];
	char response[DSD_CMD_LEN] = {0};

	snprintf(command, DSD_CMD_LEN, "[STRG%06d]", position);

	// Set Position First
	if (!dsd_command(device, command, response, sizeof(response), 100)) return false;

	if(strcmp(response, "!101)") == 0) {
		INDIGO_DRIVER_ERROR(DRIVER_NAME, "Move failed");
		return false;
	}

	// Start motion toward position
	return dsd_command(device, "[SMOV]", NULL, 0, 100);
}


static bool dsd_get_step_mode(indigo_device *device, stepmode_t *mode) {
	uint32_t _mode;
	bool res = dsd_command_get_value(device, "[GSTP]", &_mode);
	*mode = _mode;
	return res;
}


static bool dsd_set_step_mode(indigo_device *device, stepmode_t mode) {
	return dsd_command_set_value(device, "[SSTP%d]", mode);
}


static bool dsd_get_max_move(indigo_device *device, uint32_t *move) {
	return dsd_command_get_value(device, "[GMXM]", move);
}


static bool dsd_set_max_move(indigo_device *device, uint32_t move) {
	return dsd_command_set_value(device, "[SMXM%d]", move);
}


static bool dsd_get_max_position(indigo_device *device, uint32_t *position) {
	return dsd_command_get_value(device, "[GMXP]", position);
}


static bool dsd_set_max_position(indigo_device *device, uint32_t position) {
	return dsd_command_set_value(device, "[SMXP%d]", position);
}


static bool dsd_get_settle_buffer(indigo_device *device, uint32_t *buffer) {
	return dsd_command_get_value(device, "[GBUF]", buffer);
}


static bool dsd_set_settle_buffer(indigo_device *device, uint32_t buffer) {
	return dsd_command_set_value(device, "[SBUF%06d]", buffer);
}


static bool dsd_get_coils_timeout(indigo_device *device, uint32_t *to) {
	return dsd_command_get_value(device, "[GIDC]", to);
}


static bool dsd_set_coils_timeout(indigo_device *device, uint32_t to) {
	return dsd_command_set_value(device, "[SIDC%06d]", to);
}


static bool dsd_get_coils_mode(indigo_device *device, coilsmode_t *mode) {
	uint32_t _mode;
	bool res = dsd_command_get_value(device, "[GCLM]", &_mode);
	*mode = _mode;
	return res;
}


static bool dsd_set_coils_mode(indigo_device *device, coilsmode_t mode) {
	if (mode > 2) return false;
	return dsd_command_set_value(device, "[SCLM%d]", mode);
}


/* Available on AF version < 3 */
static bool dsd_get_move_current(indigo_device *device, uint32_t *current) {
	return dsd_command_get_value(device, "[GCMV%]", current);
}


/* Available on AF version < 3 */
static bool dsd_set_move_current(indigo_device *device, uint32_t current) {
	if (current > 100) return false;
	return dsd_command_set_value(device, "[SCMV%d%%]", current);
}


/* Available on AF version < 3 */
static bool dsd_get_hold_current(indigo_device *device, uint32_t *current) {
	return dsd_command_get_value(device, "[GCHD%]", current);
}


/* Available on AF version < 3 */
static bool dsd_set_hold_current(indigo_device *device, uint32_t current) {
	if (current > 100) return false;
	return dsd_command_set_value(device, "[SCHD%d%%]", current);
}


/* Available on AF version 3 */
static bool dsd_get_move_current_multiplier(indigo_device *device, uint32_t *current) {
	return dsd_command_get_value(device, "[GMMM]", current);
}


/* Available on AF version 3 */
static bool dsd_set_move_current_multiplier(indigo_device *device, uint32_t current) {
	if (current > 100) return false;
	return dsd_command_set_value(device, "[SMMM%d]", current);
}


/* Available on AF version 3 */
static bool dsd_get_hold_current_multiplier(indigo_device *device, uint32_t *current) {
	return dsd_command_get_value(device, "[GMHM]", current);
}


/* Available on AF version 3 */
static bool dsd_set_hold_current_multiplier(indigo_device *device, uint32_t current) {
	if (current > 100) return false;
	return dsd_command_set_value(device, "[SMHM%d]", current);
}


static bool dsd_get_speed(indigo_device *device, uint32_t *speed) {
	return dsd_command_get_value(device, "[GSPD]", speed);
}


static bool dsd_set_speed(indigo_device *device, uint32_t speed) {
	if (speed > 5) return false;
	return dsd_command_set_value(device, "[SSPD%d]", speed);
}


static bool dsd_is_moving(indigo_device *device, bool *is_moving) {
	return dsd_command_get_value(device, "[GMOV]", (uint32_t *)is_moving);
}


static bool dsd_get_temperature(indigo_device *device, double *temperature) {
	if ((PRIVATE_DATA->focuser_version < 2) || (!temperature)) return false;

	char response[DSD_CMD_LEN]={0};
	if (dsd_command(device, "[GTMC]", response, sizeof(response), 100)) {
		int parsed = sscanf(response, "(%lf)", temperature);
		if (parsed != 1) return false;
		INDIGO_DRIVER_ERROR(DRIVER_NAME, "[GTMC] -> %s = %lf", response, *temperature);
		return true;
	}
	INDIGO_DRIVER_ERROR(DRIVER_NAME, "NO response");
	return false;
}


// -------------------------------------------------------------------------------- INDIGO focuser device implementation
static void focuser_timer_callback(indigo_device *device) {
	bool moving;
	uint32_t position;

	if (!dsd_is_moving(device, &moving)) {
		INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_is_moving(%d) failed", DEVICE_DATA->handle);
		FOCUSER_POSITION_PROPERTY->state = INDIGO_ALERT_STATE;
		FOCUSER_STEPS_PROPERTY->state = INDIGO_ALERT_STATE;
	}

	if (!dsd_get_position(device, &position)) {
		INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_get_position(%d) failed", DEVICE_DATA->handle);
		FOCUSER_POSITION_PROPERTY->state = INDIGO_ALERT_STATE;
		FOCUSER_STEPS_PROPERTY->state = INDIGO_ALERT_STATE;
	} else {
		PRIVATE_DATA->current_position = (double)position;
	}

	FOCUSER_POSITION_ITEM->number.value = PRIVATE_DATA->current_position;
	if ((!moving) || (PRIVATE_DATA->current_position == PRIVATE_DATA->target_position)) {
		FOCUSER_POSITION_PROPERTY->state = INDIGO_OK_STATE;
		FOCUSER_STEPS_PROPERTY->state = INDIGO_OK_STATE;
	} else {
		indigo_reschedule_timer(device, 0.5, &(PRIVATE_DATA->focuser_timer));
	}
	indigo_update_property(device, FOCUSER_STEPS_PROPERTY, NULL);
	indigo_update_property(device, FOCUSER_POSITION_PROPERTY, NULL);
}


static void temperature_timer_callback(indigo_device *device) {
	double temp;
	static bool has_sensor = true;
	bool moving = false;

	FOCUSER_TEMPERATURE_PROPERTY->state = INDIGO_OK_STATE;
	if (!dsd_get_temperature(device, &temp)) {
		INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_get_temperature(%d, -> %f) failed", DEVICE_DATA->handle, temp);
		FOCUSER_TEMPERATURE_PROPERTY->state = INDIGO_ALERT_STATE;
	} else {
		FOCUSER_TEMPERATURE_ITEM->number.value = temp;
		INDIGO_DRIVER_DEBUG(DRIVER_NAME, "dsd_get_temperature(%d, -> %f) succeeded", DEVICE_DATA->handle, FOCUSER_TEMPERATURE_ITEM->number.value);
	}

	if (FOCUSER_TEMPERATURE_ITEM->number.value <= NO_TEMP_READING) { /* -127 is returned when the sensor is not connected */
		FOCUSER_TEMPERATURE_PROPERTY->state = INDIGO_IDLE_STATE;
		if (has_sensor) {
			INDIGO_DRIVER_LOG(DRIVER_NAME, "The temperature sensor is not connected.");
			indigo_update_property(device, FOCUSER_TEMPERATURE_PROPERTY, "The temperature sensor is not connected.");
			has_sensor = false;
		}
	} else {
		has_sensor = true;
		indigo_update_property(device, FOCUSER_TEMPERATURE_PROPERTY, NULL);
	}
	if (FOCUSER_MODE_AUTOMATIC_ITEM->sw.value) {
		compensate_focus(device, temp);
	} else {
		/* reset temp so that the compensation starts when auto mode is selected */
		PRIVATE_DATA->prev_temp = NO_TEMP_READING;
	}

	indigo_reschedule_timer(device, 2, &(PRIVATE_DATA->temperature_timer));
}


static void compensate_focus(indigo_device *device, double new_temp) {
	int compensation;
	double temp_difference = new_temp - PRIVATE_DATA->prev_temp;

	/* we do not have previous temperature reading */
	if (PRIVATE_DATA->prev_temp <= NO_TEMP_READING) {
		INDIGO_DRIVER_DEBUG(DRIVER_NAME, "Not compensating: PRIVATE_DATA->prev_temp = %f", PRIVATE_DATA->prev_temp);
		PRIVATE_DATA->prev_temp = new_temp;
		return;
	}

	/* we do not have current temperature reading or focuser is moving */
	if ((new_temp <= NO_TEMP_READING) || (FOCUSER_POSITION_PROPERTY->state != INDIGO_OK_STATE)) {
		INDIGO_DRIVER_DEBUG(DRIVER_NAME, "Not compensating: new_temp = %f, FOCUSER_POSITION_PROPERTY->state = %d", new_temp, FOCUSER_POSITION_PROPERTY->state);
		return;
	}

	/* temperature difference if more than 1 degree so compensation needed */
	if ((fabs(temp_difference) >= 1.0) && (fabs(temp_difference) < 100)) {
		compensation = (int)(temp_difference * FOCUSER_COMPENSATION_ITEM->number.value);
		INDIGO_DRIVER_DEBUG(DRIVER_NAME, "Compensation: temp_difference = %.2f, Compensation = %d, steps/degC = %.1f", temp_difference, compensation, FOCUSER_COMPENSATION_ITEM->number.value);
	} else {
		INDIGO_DRIVER_DEBUG(DRIVER_NAME, "Not compensating (not needed): temp_difference = %f", temp_difference);
		return;
	}

	PRIVATE_DATA->target_position = PRIVATE_DATA->current_position + compensation;
	INDIGO_DRIVER_DEBUG(DRIVER_NAME, "Compensation: PRIVATE_DATA->current_position = %d, PRIVATE_DATA->target_position = %d", PRIVATE_DATA->current_position, PRIVATE_DATA->target_position);

	uint32_t current_position;
	if (!dsd_get_position(device, &current_position)) {
		INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_get_position(%d) failed", DEVICE_DATA->handle);
	}
	PRIVATE_DATA->current_position = (double)current_position;

	/* Make sure we do not attempt to go beyond the limits */
	if (FOCUSER_POSITION_ITEM->number.max < PRIVATE_DATA->target_position) {
		PRIVATE_DATA->target_position = FOCUSER_POSITION_ITEM->number.max;
	} else if (FOCUSER_POSITION_ITEM->number.min > PRIVATE_DATA->target_position) {
		PRIVATE_DATA->target_position = FOCUSER_POSITION_ITEM->number.min;
	}
	INDIGO_DRIVER_DEBUG(DRIVER_NAME, "Compensating: Corrected PRIVATE_DATA->target_position = %d", PRIVATE_DATA->target_position);

	if (!dsd_goto_position(device, (uint32_t)PRIVATE_DATA->target_position)) {
		INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_goto_position(%d, %d) failed", DEVICE_DATA->handle, PRIVATE_DATA->target_position);
		FOCUSER_STEPS_PROPERTY->state = INDIGO_ALERT_STATE;
	}

	PRIVATE_DATA->prev_temp = new_temp;
	FOCUSER_POSITION_ITEM->number.value = PRIVATE_DATA->current_position;
	FOCUSER_POSITION_PROPERTY->state = INDIGO_BUSY_STATE;
	indigo_update_property(device, FOCUSER_POSITION_PROPERTY, NULL);
	PRIVATE_DATA->focuser_timer = indigo_set_timer(device, 0.5, focuser_timer_callback);
}


static indigo_result dsd_enumerate_properties(indigo_device *device, indigo_client *client, indigo_property *property) {
	if (IS_CONNECTED) {
		if (indigo_property_match(DSD_STEP_MODE_PROPERTY, property))
			indigo_define_property(device, DSD_STEP_MODE_PROPERTY, NULL);
		if (indigo_property_match(DSD_COILS_MODE_PROPERTY, property))
			indigo_define_property(device, DSD_COILS_MODE_PROPERTY, NULL);
		if (indigo_property_match(DSD_CURRENT_CONTROL_PROPERTY, property))
			indigo_define_property(device, DSD_CURRENT_CONTROL_PROPERTY, NULL);
		if (indigo_property_match(DSD_TIMINGS_PROPERTY, property))
			indigo_define_property(device, DSD_TIMINGS_PROPERTY, NULL);
	}
	indigo_define_property(device, LA_MODEL_HINT_PROPERTY, NULL);
	return indigo_focuser_enumerate_properties(device, NULL, NULL);
}


static indigo_result focuser_attach(indigo_device *device) {
	assert(device != NULL);
	assert(PRIVATE_DATA != NULL);
	if (indigo_focuser_attach(device, DRIVER_VERSION) == INDIGO_OK) {
		pthread_mutex_init(&DEVICE_DATA->port_mutex, NULL);
		// -------------------------------------------------------------------------------- SIMULATION
		SIMULATION_PROPERTY->hidden = true;
		// -------------------------------------------------------------------------------- DEVICE_PORT
		DEVICE_PORT_PROPERTY->hidden = false;
		// -------------------------------------------------------------------------------- DEVICE_PORTS
		DEVICE_PORTS_PROPERTY->hidden = false;
		// -------------------------------------------------------------------------------- DEVICE_BAUDRATE
		DEVICE_BAUDRATE_PROPERTY->hidden = false;
		strncpy(DEVICE_BAUDRATE_ITEM->text.value, DSD_AF1_AF2_BAUDRATE, INDIGO_VALUE_SIZE);
		// --------------------------------------------------------------------------------
		INFO_PROPERTY->count = 5;

		FOCUSER_LIMITS_PROPERTY->hidden = false;
		FOCUSER_LIMITS_MAX_POSITION_ITEM->number.min = 10000;
		FOCUSER_LIMITS_MAX_POSITION_ITEM->number.max = 1000000;
		FOCUSER_LIMITS_MAX_POSITION_ITEM->number.step = FOCUSER_LIMITS_MAX_POSITION_ITEM->number.min;

		FOCUSER_LIMITS_MIN_POSITION_ITEM->number.min = 0;
		FOCUSER_LIMITS_MIN_POSITION_ITEM->number.value = 0;
		FOCUSER_LIMITS_MIN_POSITION_ITEM->number.max = 0;

		FOCUSER_SPEED_PROPERTY->hidden = false;
		FOCUSER_SPEED_ITEM->number.min = 1;
		FOCUSER_SPEED_ITEM->number.max = 5;
		FOCUSER_SPEED_ITEM->number.step = 1;

		FOCUSER_POSITION_ITEM->number.min = 0;
		FOCUSER_POSITION_ITEM->number.step = 100;
		FOCUSER_POSITION_ITEM->number.max = FOCUSER_LIMITS_MAX_POSITION_ITEM->number.max;

		FOCUSER_STEPS_ITEM->number.min = 0;
		FOCUSER_STEPS_ITEM->number.step = 1;
		//FOCUSER_STEPS_ITEM->number.max = PRIVATE_DATA->info.MaxStep;

		FOCUSER_ON_POSITION_SET_PROPERTY->hidden = false;
		FOCUSER_REVERSE_MOTION_PROPERTY->hidden = false;

		// -------------------------------------------------------------------------- LA_MODEL_HINT_PROPERTY
		LA_MODEL_HINT_PROPERTY = indigo_init_switch_property(NULL, device->name, LA_MODEL_HINT_PROPERTY_NAME, MAIN_GROUP, "Focuser model hint", INDIGO_OK_STATE, INDIGO_RW_PERM, INDIGO_ONE_OF_MANY_RULE, 3);
		if (LA_MODEL_HINT_PROPERTY == NULL)
			return INDIGO_FAILED;
		indigo_init_switch_item(LA_MODEL_AUTO_ITEM, LA_MODEL_AUTO_ITEM_NAME, "Auto detect (on connect)", true);
		indigo_init_switch_item(LA_MODEL_ARMADILLO_ITEM, LA_MODEL_ARMADILLO_ITEM_NAME, "Armadillo (2 ports)", false);
		indigo_init_switch_item(LA_MODEL_PLATIPUS_ITEM, LA_MODEL_PLATIPUS_ITEM_NAME, "Platipus (3 ports)", false);
		// -------------------------------------------------------------------------- STEP_MODE_PROPERTY
		DSD_STEP_MODE_PROPERTY = indigo_init_switch_property(NULL, device->name, DSD_STEP_MODE_PROPERTY_NAME, "Advanced", "Step mode", INDIGO_OK_STATE, INDIGO_RW_PERM, INDIGO_ONE_OF_MANY_RULE, 9);
		if (DSD_STEP_MODE_PROPERTY == NULL)
			return INDIGO_FAILED;
		DSD_STEP_MODE_PROPERTY->hidden = false;
		indigo_init_switch_item(DSD_STEP_MODE_FULL_ITEM, DSD_STEP_MODE_FULL_ITEM_NAME, "Full step", false);
		indigo_init_switch_item(DSD_STEP_MODE_HALF_ITEM, DSD_STEP_MODE_HALF_ITEM_NAME, "1/2 step", false);
		indigo_init_switch_item(DSD_STEP_MODE_FOURTH_ITEM, DSD_STEP_MODE_FOURTH_ITEM_NAME, "1/4 step", false);
		indigo_init_switch_item(DSD_STEP_MODE_EIGTH_ITEM, DSD_STEP_MODE_EIGTH_ITEM_NAME, "1/8 step", false);
		indigo_init_switch_item(DSD_STEP_MODE_16TH_ITEM, DSD_STEP_MODE_16TH_ITEM_NAME, "1/16 step", false);
		indigo_init_switch_item(DSD_STEP_MODE_32TH_ITEM, DSD_STEP_MODE_32TH_ITEM_NAME, "1/32 step", false);
		indigo_init_switch_item(DSD_STEP_MODE_64TH_ITEM, DSD_STEP_MODE_64TH_ITEM_NAME, "1/64 step", false);
		indigo_init_switch_item(DSD_STEP_MODE_128TH_ITEM, DSD_STEP_MODE_128TH_ITEM_NAME, "1/128 step", false);
		indigo_init_switch_item(DSD_STEP_MODE_256TH_ITEM, DSD_STEP_MODE_256TH_ITEM_NAME, "1/256 step", false);

		// -------------------------------------------------------------------------- COILS_MODE_PROPERTY
		DSD_COILS_MODE_PROPERTY = indigo_init_switch_property(NULL, device->name, DSD_COILS_MODE_PROPERTY_NAME, "Advanced", "Coils Power", INDIGO_OK_STATE, INDIGO_RW_PERM, INDIGO_ONE_OF_MANY_RULE, 3);
		if (DSD_COILS_MODE_PROPERTY == NULL)
			return INDIGO_FAILED;
		DSD_COILS_MODE_PROPERTY->hidden = false;
		indigo_init_switch_item(DSD_COILS_MODE_IDLE_OFF_ITEM, DSD_COILS_MODE_IDLE_OFF_ITEM_NAME, "OFF when idle", false);
		indigo_init_switch_item(DSD_COILS_MODE_ALWAYS_ON_ITEM, DSD_COILS_MODE_ALWAYS_ON_ITEM_NAME, "Always ON", false);
		indigo_init_switch_item(DSD_COILS_MODE_TIMEOUT_ITEM, DSD_COILS_MODE_TIMEOUT_ITEM_NAME, "OFF after timeout", false);
		//--------------------------------------------------------------------------- CURRENT_CONTROL_PROPERTY
		DSD_CURRENT_CONTROL_PROPERTY = indigo_init_number_property(NULL, device->name, DSD_CURRENT_CONTROL_PROPERTY_NAME, "Advanced", "Coils current control", INDIGO_OK_STATE, INDIGO_RW_PERM, 2);
		if (DSD_CURRENT_CONTROL_PROPERTY == NULL)
			return INDIGO_FAILED;
		indigo_init_number_item(DSD_CURRENT_CONTROL_MOVE_ITEM, DSD_CURRENT_CONTROL_MOVE_ITEM_NAME, "Move current (%)", 10, 100, 1, 50);
		indigo_init_number_item(DSD_CURRENT_CONTROL_HOLD_ITEM, DSD_CURRENT_CONTROL_HOLD_ITEM_NAME, "Hold current (%)", 10, 100, 1, 50);
		//--------------------------------------------------------------------------- TIMINGS_PROPERTY
		DSD_TIMINGS_PROPERTY = indigo_init_number_property(NULL, device->name, DSD_TIMINGS_PROPERTY_NAME, "Advanced", "Timing settings", INDIGO_OK_STATE, INDIGO_RW_PERM, 2);
		if (DSD_TIMINGS_PROPERTY == NULL)
			return INDIGO_FAILED;
		indigo_init_number_item(DSD_TIMINGS_SETTLE_ITEM, DSD_TIMINGS_SETTLE_ITEM_NAME, "Settle time (ms)", 0, 99999, 100, 0);
		indigo_init_number_item(DSD_TIMINGS_COILS_TOUT_ITEM, DSD_TIMINGS_COILS_TOUT_ITEM_NAME, "Coils power timeout (ms)", 9, 999999, 1000, 60000);
		// --------------------------------------------------------------------------
		INDIGO_DEVICE_ATTACH_LOG(DRIVER_NAME, device->name);
		indigo_define_property(device, LA_MODEL_HINT_PROPERTY, NULL);
		return indigo_focuser_enumerate_properties(device, NULL, NULL);
	}
	return INDIGO_FAILED;
}

static void update_step_mode_switches(indigo_device * device) {
	stepmode_t value;

	if (!dsd_get_step_mode(device, &value)) {
		INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_get_step_mode(%d) failed", DEVICE_DATA->handle);
		return;
	}

	switch (value) {
	case STEP_MODE_FULL:
		indigo_set_switch(DSD_STEP_MODE_PROPERTY, DSD_STEP_MODE_FULL_ITEM, true);
		break;
	case STEP_MODE_HALF:
		indigo_set_switch(DSD_STEP_MODE_PROPERTY, DSD_STEP_MODE_HALF_ITEM, true);
		break;
	case STEP_MODE_FOURTH:
		indigo_set_switch(DSD_STEP_MODE_PROPERTY, DSD_STEP_MODE_FOURTH_ITEM, true);
		break;
	case STEP_MODE_EIGTH:
		indigo_set_switch(DSD_STEP_MODE_PROPERTY, DSD_STEP_MODE_EIGTH_ITEM, true);
		break;
	case STEP_MODE_16TH:
		indigo_set_switch(DSD_STEP_MODE_PROPERTY, DSD_STEP_MODE_16TH_ITEM, true);
		break;
	case STEP_MODE_32TH:
		indigo_set_switch(DSD_STEP_MODE_PROPERTY, DSD_STEP_MODE_32TH_ITEM, true);
		break;
	case STEP_MODE_64TH:
		indigo_set_switch(DSD_STEP_MODE_PROPERTY, DSD_STEP_MODE_64TH_ITEM, true);
		break;
	case STEP_MODE_128TH:
		indigo_set_switch(DSD_STEP_MODE_PROPERTY, DSD_STEP_MODE_128TH_ITEM, true);
		break;
	case STEP_MODE_256TH:
		indigo_set_switch(DSD_STEP_MODE_PROPERTY, DSD_STEP_MODE_256TH_ITEM, true);
		break;
	default:
		INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_get_step_mode(%d) wrong value %d", DEVICE_DATA->handle, value);
	}
}


static void update_coils_mode_switches(indigo_device * device) {
	coilsmode_t value;

	if (!dsd_get_coils_mode(device, &value)) {
		INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_get_coils_mode(%d) failed", DEVICE_DATA->handle);
		return;
	}

	switch (value) {
	case COILS_MODE_IDLE_OFF:
		indigo_set_switch(DSD_COILS_MODE_PROPERTY, DSD_COILS_MODE_IDLE_OFF_ITEM, true);
		break;
	case COILS_MODE_ALWAYS_ON:
		indigo_set_switch(DSD_COILS_MODE_PROPERTY, DSD_COILS_MODE_ALWAYS_ON_ITEM, true);
		break;
	case COILS_MODE_IDLE_TIMEOUT:
		indigo_set_switch(DSD_COILS_MODE_PROPERTY, DSD_COILS_MODE_TIMEOUT_ITEM, true);
		break;
	default:
		INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_get_coils_mode(%d) wrong value %d", DEVICE_DATA->handle, value);
	}
}


static bool lunatico_open(indigo_device *device) {
	if (device->is_connected) return false;

	pthread_mutex_lock(&DEVICE_DATA->port_mutex);
	if (DEVICE_DATA->count_open++ == 0) {
		if (indigo_try_global_lock(device) != INDIGO_OK) {
			pthread_mutex_unlock(&DEVICE_DATA->port_mutex);
			INDIGO_DRIVER_ERROR(DRIVER_NAME, "indigo_try_global_lock(): failed to get lock.");
			DEVICE_DATA->count_open--;
			return false;
		}
		char *name = DEVICE_PORT_ITEM->text.value;
		if (strncmp(name, "dsd://", 6)) {
			DEVICE_DATA->handle = indigo_open_serial_with_speed(name, atoi(DEVICE_BAUDRATE_ITEM->text.value));
		} else {
			char *host = name + 6;
			char *colon = strchr(host, ':');
			if (colon == NULL) {
				DEVICE_DATA->handle = indigo_open_tcp(host, 8080);
			} else {
				char host_name[INDIGO_NAME_SIZE];
				strncpy(host_name, host, colon - host);
				host_name[colon - host] = 0;
				int port = atoi(colon + 1);
				DEVICE_DATA->handle = indigo_open_tcp(host_name, port);
			}
		}
		if (DEVICE_DATA->handle < 0) {
			INDIGO_DRIVER_ERROR(DRIVER_NAME, "indigo_open_serial(%s): failed", DEVICE_PORT_ITEM->text.value);
			CONNECTION_PROPERTY->state = INDIGO_ALERT_STATE;
			indigo_set_switch(CONNECTION_PROPERTY, CONNECTION_DISCONNECTED_ITEM, true);
			indigo_update_property(device, CONNECTION_PROPERTY, NULL);
			indigo_global_unlock(device);
			pthread_mutex_unlock(&DEVICE_DATA->port_mutex);
			DEVICE_DATA->count_open--;
			return false;
		}
	}
	pthread_mutex_unlock(&DEVICE_DATA->port_mutex);
	return true;
}

static void lunatico_close(indigo_device *device) {

	if (!device->is_connected) return;

	pthread_mutex_lock(&DEVICE_DATA->port_mutex);
	if (--DEVICE_DATA->count_open == 0) {
		close(DEVICE_DATA->handle);
		INDIGO_DRIVER_DEBUG(DRIVER_NAME, "close(%d)", DEVICE_DATA->handle);
		indigo_global_unlock(device);
		DEVICE_DATA->handle = 0;
	}
	pthread_mutex_unlock(&DEVICE_DATA->port_mutex);
}


static indigo_result focuser_change_property(indigo_device *device, indigo_client *client, indigo_property *property) {
	assert(device != NULL);
	assert(DEVICE_CONTEXT != NULL);
	assert(property != NULL);
	if (indigo_property_match(CONNECTION_PROPERTY, property)) {
		// -------------------------------------------------------------------------------- CONNECTION
		indigo_property_copy_values(CONNECTION_PROPERTY, property, false);
		int position;
		if (CONNECTION_CONNECTED_ITEM->sw.value) {
			if (!device->is_connected) {
				CONNECTION_PROPERTY->state = INDIGO_BUSY_STATE;
				indigo_update_property(device, CONNECTION_PROPERTY, NULL);
				pthread_mutex_lock(&DEVICE_DATA->port_mutex);
				if (indigo_try_global_lock(device) != INDIGO_OK) {
					pthread_mutex_unlock(&DEVICE_DATA->port_mutex);
					INDIGO_DRIVER_ERROR(DRIVER_NAME, "indigo_try_global_lock(): failed to get lock.");
					CONNECTION_PROPERTY->state = INDIGO_ALERT_STATE;
					indigo_set_switch(CONNECTION_PROPERTY, CONNECTION_DISCONNECTED_ITEM, true);
					indigo_update_property(device, CONNECTION_PROPERTY, NULL);
				} else {
					pthread_mutex_unlock(&DEVICE_DATA->port_mutex);
					char *name = DEVICE_PORT_ITEM->text.value;
					if (strncmp(name, "dsd://", 6)) {
						DEVICE_DATA->handle = indigo_open_serial_with_speed(name, atoi(DEVICE_BAUDRATE_ITEM->text.value));
						/* DSD resets on RTS, which is manipulated on connect! Wait for 2 seconds to recover! */
						sleep(2);
					} else {
						char *host = name + 6;
						char *colon = strchr(host, ':');
						if (colon == NULL) {
							DEVICE_DATA->handle = indigo_open_tcp(host, 8080);
						} else {
							char host_name[INDIGO_NAME_SIZE];
							strncpy(host_name, host, colon - host);
							host_name[colon - host] = 0;
							int port = atoi(colon + 1);
							DEVICE_DATA->handle = indigo_open_tcp(host_name, port);
						}
					}
					if ( DEVICE_DATA->handle < 0) {
						INDIGO_DRIVER_ERROR(DRIVER_NAME, " indigo_open_serial(%s): failed", DEVICE_PORT_ITEM->text.value);
						CONNECTION_PROPERTY->state = INDIGO_ALERT_STATE;
						indigo_set_switch(CONNECTION_PROPERTY, CONNECTION_DISCONNECTED_ITEM, true);
						indigo_update_property(device, CONNECTION_PROPERTY, NULL);
						indigo_global_unlock(device);
						return INDIGO_OK;
					} else if (!dsd_get_position(device, &position)) {  // check if it is DSD Focuser first
						int res = close(DEVICE_DATA->handle);
						if (res < 0) {
							INDIGO_DRIVER_ERROR(DRIVER_NAME, "close(%d) = %d", DEVICE_DATA->handle, res);
						} else {
							INDIGO_DRIVER_DEBUG(DRIVER_NAME, "close(%d) = %d", DEVICE_DATA->handle, res);
						}
						indigo_global_unlock(device);
						device->is_connected = false;
						INDIGO_DRIVER_ERROR(DRIVER_NAME, "connect failed: Deep Sky Dad AF did not respond");
						CONNECTION_PROPERTY->state = INDIGO_ALERT_STATE;
						indigo_set_switch(CONNECTION_PROPERTY, CONNECTION_DISCONNECTED_ITEM, true);
						indigo_update_property(device, CONNECTION_PROPERTY, "Deep Sky Dad AF did not respond");
						return INDIGO_OK;;
					} else { // Successfully connected
						char board[DSD_CMD_LEN] = "N/A";
						char firmware[DSD_CMD_LEN] = "N/A";
						uint32_t value;
						if (dsd_get_info(device, board, firmware)) {
							strncpy(INFO_DEVICE_MODEL_ITEM->text.value, board, INDIGO_VALUE_SIZE);
							strncpy(INFO_DEVICE_FW_REVISION_ITEM->text.value, firmware, INDIGO_VALUE_SIZE);
							indigo_update_property(device, INFO_PROPERTY, NULL);
							if (strstr(board, "AF1")) {
								PRIVATE_DATA->focuser_version = 1;
							} else if (strstr(board, "AF2")) {
								PRIVATE_DATA->focuser_version = 2;
							} else if (strstr(board, "AF3")) {
								PRIVATE_DATA->focuser_version = 3;
							}
							INDIGO_DRIVER_ERROR(DRIVER_NAME, "version = %d", PRIVATE_DATA->focuser_version);
						}
						//PRIVATE_DATA->focuser_version = 3;
						if (PRIVATE_DATA->focuser_version < 3) {
							/* DSD version < 3 suports speeds from 1 to 3 */
							FOCUSER_SPEED_ITEM->number.max = 3;

							/* DSD version < 3 suports steps from full to 1/8 */
							DSD_STEP_MODE_PROPERTY->count = 4;
						} else {
							/* DSD version 3 does not have coils mode */
							DSD_COILS_MODE_PROPERTY->hidden = true;
							/* DSD version 3 does not have coils timeout */
							DSD_TIMINGS_PROPERTY->count = 1;

							/* Current mulipliers in AF 3 are in range 1-100 */
							DSD_CURRENT_CONTROL_MOVE_ITEM->number.min = 1.0;
							DSD_CURRENT_CONTROL_HOLD_ITEM->number.min = 1.0;
							strncpy(DSD_CURRENT_CONTROL_MOVE_ITEM->label, "Move current multiplier (%)", INDIGO_VALUE_SIZE);
							strncpy(DSD_CURRENT_CONTROL_HOLD_ITEM->label, "Hold current multiplier (%)", INDIGO_VALUE_SIZE);
						}

						dsd_get_position(device, &position);
						FOCUSER_POSITION_ITEM->number.value = (double)position;

						if (!dsd_get_max_position(device, &PRIVATE_DATA->max_position)) {
							INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_get_max_position(%d) failed", DEVICE_DATA->handle);
						}
						FOCUSER_LIMITS_MAX_POSITION_ITEM->number.value = (double)PRIVATE_DATA->max_position;

						if (!dsd_get_speed(device, &value)) {
							INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_get_speed(%d) failed", DEVICE_DATA->handle);
						}
						FOCUSER_SPEED_ITEM->number.value = (double)value;

						/* While we do not have max move property hardoce it to max position */
						dsd_set_max_move(device, (uint32_t)FOCUSER_POSITION_ITEM->number.max);

						/* DSD does not have reverse motion, so we set it to be sure we know its state */
						dsd_set_reverse(device, FOCUSER_REVERSE_MOTION_ENABLED_ITEM->sw.value);

						update_step_mode_switches(device);
						indigo_define_property(device, DSD_STEP_MODE_PROPERTY, NULL);

						if (PRIVATE_DATA->focuser_version < 3) {
							update_coils_mode_switches(device);
							indigo_define_property(device, DSD_COILS_MODE_PROPERTY, NULL);

							if (!dsd_get_move_current(device, &value)) {
								INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_get_move_current(%d) failed", DEVICE_DATA->handle);
							}
							DSD_CURRENT_CONTROL_MOVE_ITEM->number.value = (double)value;
							DSD_CURRENT_CONTROL_MOVE_ITEM->number.target = (double)value;
							if (!dsd_get_hold_current(device, &value)) {
								INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_get_hold_current(%d) failed", DEVICE_DATA->handle);
							}
							DSD_CURRENT_CONTROL_HOLD_ITEM->number.value = (double)value;
							DSD_CURRENT_CONTROL_HOLD_ITEM->number.target = (double)value;
						} else {
							if (!dsd_get_move_current_multiplier(device, &value)) {
								INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_get_move_current_multiplier(%d) failed", DEVICE_DATA->handle);
							}
							DSD_CURRENT_CONTROL_MOVE_ITEM->number.value = (double)value;
							DSD_CURRENT_CONTROL_MOVE_ITEM->number.target = (double)value;
							if (!dsd_get_hold_current_multiplier(device, &value)) {
								INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_get_hold_current_multiplier(%d) failed", DEVICE_DATA->handle);
							}
							DSD_CURRENT_CONTROL_HOLD_ITEM->number.value = (double)value;
							DSD_CURRENT_CONTROL_HOLD_ITEM->number.target = (double)value;
						}
						indigo_define_property(device, DSD_CURRENT_CONTROL_PROPERTY, NULL);

						if (!dsd_get_settle_buffer(device, &value)) {
							INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_get_settle_buffer(%d) failed", DEVICE_DATA->handle);
						}
						DSD_TIMINGS_SETTLE_ITEM->number.value = (double)value;
						DSD_TIMINGS_SETTLE_ITEM->number.target = (double)value;
						/* DSD AF3 does not have coils timeout */
						if (PRIVATE_DATA->focuser_version < 3) {
							if (!dsd_get_coils_timeout(device, &value)) {
								INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_get_coils_timeout(%d) failed", DEVICE_DATA->handle);
							}
							DSD_TIMINGS_COILS_TOUT_ITEM->number.value = (double)value;
							DSD_TIMINGS_COILS_TOUT_ITEM->number.target = (double)value;
						}
						indigo_define_property(device, DSD_TIMINGS_PROPERTY, NULL);

						CONNECTION_PROPERTY->state = INDIGO_OK_STATE;
						device->is_connected = true;

						PRIVATE_DATA->focuser_timer = indigo_set_timer(device, 0.5, focuser_timer_callback);

						if (PRIVATE_DATA->focuser_version > 1) {
							FOCUSER_MODE_PROPERTY->hidden = false;
							FOCUSER_TEMPERATURE_PROPERTY->hidden = false;
							dsd_get_temperature(device, &FOCUSER_TEMPERATURE_ITEM->number.value);
							PRIVATE_DATA->prev_temp = FOCUSER_TEMPERATURE_ITEM->number.value;
							FOCUSER_COMPENSATION_PROPERTY->hidden = false;
							FOCUSER_COMPENSATION_ITEM->number.min = -10000;
							FOCUSER_COMPENSATION_ITEM->number.max = 10000;
							PRIVATE_DATA->temperature_timer = indigo_set_timer(device, 1, temperature_timer_callback);
						} else {
							FOCUSER_MODE_PROPERTY->hidden = true;
						}
					}
				}
			}
		} else {
			if (device->is_connected) {
				indigo_cancel_timer(device, &PRIVATE_DATA->focuser_timer);
				if (PRIVATE_DATA->focuser_version > 1) {
					indigo_cancel_timer(device, &PRIVATE_DATA->temperature_timer);
				}
				indigo_delete_property(device, DSD_STEP_MODE_PROPERTY, NULL);
				indigo_delete_property(device, DSD_COILS_MODE_PROPERTY, NULL);
				indigo_delete_property(device, DSD_CURRENT_CONTROL_PROPERTY, NULL);
				indigo_delete_property(device, DSD_TIMINGS_PROPERTY, NULL);

				pthread_mutex_lock(&DEVICE_DATA->port_mutex);
				int res = close(DEVICE_DATA->handle);
				if (res < 0) {
					INDIGO_DRIVER_ERROR(DRIVER_NAME, "close(%d) = %d", DEVICE_DATA->handle, res);
				} else {
					INDIGO_DRIVER_DEBUG(DRIVER_NAME, "close(%d) = %d", DEVICE_DATA->handle, res);
				}
				indigo_global_unlock(device);
				pthread_mutex_unlock(&DEVICE_DATA->port_mutex);
				device->is_connected = false;
				CONNECTION_PROPERTY->state = INDIGO_OK_STATE;
			}
		}
	} else if (indigo_property_match(LA_MODEL_HINT_PROPERTY, property)) {
		// -------------------------------------------------------------------------------- DSD_MODEL_HINT
		indigo_property_copy_values(LA_MODEL_HINT_PROPERTY, property, false);
		LA_MODEL_HINT_PROPERTY->state = INDIGO_OK_STATE;
		if (LA_MODEL_PLATIPUS_ITEM->sw.value) {
			create_device(0, 2, "Third");
		} else {
			delete_device(0, 2);
		}
		indigo_update_property(device, LA_MODEL_HINT_PROPERTY, NULL);
		return INDIGO_OK;
	} else if (indigo_property_match(FOCUSER_REVERSE_MOTION_PROPERTY, property)) {
		// -------------------------------------------------------------------------------- FOCUSER_REVERSE_MOTION
		if (!IS_CONNECTED) return INDIGO_OK;
		indigo_property_copy_values(FOCUSER_REVERSE_MOTION_PROPERTY, property, false);
		FOCUSER_REVERSE_MOTION_PROPERTY->state = INDIGO_OK_STATE;
		if (!dsd_set_reverse(device, FOCUSER_REVERSE_MOTION_ENABLED_ITEM->sw.value)) {
			INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_set_reverse(%d, %d) failed", DEVICE_DATA->handle, FOCUSER_REVERSE_MOTION_ENABLED_ITEM->sw.value);
			FOCUSER_REVERSE_MOTION_PROPERTY->state = INDIGO_ALERT_STATE;
		}
		indigo_update_property(device, FOCUSER_REVERSE_MOTION_PROPERTY, NULL);
		return INDIGO_OK;
	} else if (indigo_property_match(FOCUSER_POSITION_PROPERTY, property)) {
		// -------------------------------------------------------------------------------- FOCUSER_POSITION
		indigo_property_copy_values(FOCUSER_POSITION_PROPERTY, property, false);
		if (FOCUSER_POSITION_ITEM->number.target < 0 || FOCUSER_POSITION_ITEM->number.target > FOCUSER_POSITION_ITEM->number.max) {
			FOCUSER_POSITION_PROPERTY->state = INDIGO_ALERT_STATE;
		} else if (FOCUSER_POSITION_ITEM->number.target == PRIVATE_DATA->current_position) {
			FOCUSER_POSITION_PROPERTY->state = INDIGO_OK_STATE;
		} else { /* GOTO position */
			FOCUSER_POSITION_PROPERTY->state = INDIGO_BUSY_STATE;
			PRIVATE_DATA->target_position = FOCUSER_POSITION_ITEM->number.target;
			FOCUSER_POSITION_ITEM->number.value = PRIVATE_DATA->current_position;
			if (FOCUSER_ON_POSITION_SET_GOTO_ITEM->sw.value) { /* GOTO POSITION */
				FOCUSER_POSITION_PROPERTY->state = INDIGO_BUSY_STATE;
				if (!dsd_goto_position(device, (uint32_t)PRIVATE_DATA->target_position)) {
					INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_goto_position(%d, %d) failed", DEVICE_DATA->handle, PRIVATE_DATA->target_position);
					FOCUSER_POSITION_PROPERTY->state = INDIGO_ALERT_STATE;
				}
				PRIVATE_DATA->focuser_timer = indigo_set_timer(device, 0.5, focuser_timer_callback);
			} else { /* RESET CURRENT POSITION */
				FOCUSER_POSITION_PROPERTY->state = INDIGO_OK_STATE;
				if(!dsd_sync_position(device, PRIVATE_DATA->target_position)) {
					INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_sync_position(%d, %d) failed", DEVICE_DATA->handle, PRIVATE_DATA->target_position);
					FOCUSER_POSITION_PROPERTY->state = INDIGO_ALERT_STATE;
				}
				uint32_t position;
				if (!dsd_get_position(device, &position)) {
					INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_get_position(%d) failed", DEVICE_DATA->handle);
					FOCUSER_POSITION_PROPERTY->state = INDIGO_ALERT_STATE;
				} else {
					FOCUSER_POSITION_ITEM->number.value = PRIVATE_DATA->current_position = (double)position;
				}
			}
		}
		indigo_update_property(device, FOCUSER_POSITION_PROPERTY, NULL);
		return INDIGO_OK;
	} else if (indigo_property_match(FOCUSER_LIMITS_PROPERTY, property)) {
		// -------------------------------------------------------------------------------- FOCUSER_LIMITS
		if (!IS_CONNECTED) return INDIGO_OK;
		indigo_property_copy_values(FOCUSER_LIMITS_PROPERTY, property, false);
		FOCUSER_LIMITS_PROPERTY->state = INDIGO_OK_STATE;
		PRIVATE_DATA->max_position = (int)FOCUSER_LIMITS_MAX_POSITION_ITEM->number.target;
		if (!dsd_set_max_position(device, PRIVATE_DATA->max_position)) {
			INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_set_max_position(%d) failed", DEVICE_DATA->handle);
			FOCUSER_LIMITS_PROPERTY->state = INDIGO_ALERT_STATE;
		}
		if (!dsd_get_max_position(device, &PRIVATE_DATA->max_position)) {
			INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_get_max_position(%d) failed", DEVICE_DATA->handle);
		}
		FOCUSER_LIMITS_MAX_POSITION_ITEM->number.value = (double)PRIVATE_DATA->max_position;
		indigo_update_property(device, FOCUSER_LIMITS_PROPERTY, NULL);
		return INDIGO_OK;
	} else if (indigo_property_match(FOCUSER_SPEED_PROPERTY, property)) {
		// -------------------------------------------------------------------------------- FOCUSER_SPEED
		if (!IS_CONNECTED) return INDIGO_OK;
		indigo_property_copy_values(FOCUSER_SPEED_PROPERTY, property, false);
		FOCUSER_SPEED_PROPERTY->state = INDIGO_OK_STATE;
		if (!dsd_set_speed(device, (uint32_t)FOCUSER_SPEED_ITEM->number.target)) {
			INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_set_speed(%d) failed", DEVICE_DATA->handle);
			FOCUSER_SPEED_PROPERTY->state = INDIGO_ALERT_STATE;
		}
		uint32_t speed;
		if (!dsd_get_speed(device, &speed)) {
			INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_get_speed(%d) failed", DEVICE_DATA->handle);
		}
		FOCUSER_SPEED_ITEM->number.value = (double)speed;
		indigo_update_property(device, FOCUSER_SPEED_PROPERTY, NULL);
		return INDIGO_OK;
	} else if (indigo_property_match(FOCUSER_STEPS_PROPERTY, property)) {
		// -------------------------------------------------------------------------------- FOCUSER_STEPS
		indigo_property_copy_values(FOCUSER_STEPS_PROPERTY, property, false);
		if (FOCUSER_STEPS_ITEM->number.value < 0 || FOCUSER_STEPS_ITEM->number.value > FOCUSER_STEPS_ITEM->number.max) {
			FOCUSER_STEPS_PROPERTY->state = INDIGO_ALERT_STATE;
		} else {
			FOCUSER_STEPS_PROPERTY->state = INDIGO_BUSY_STATE;
			uint32_t position;
			if (!dsd_get_position(device, &position)) {
				INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_get_position(%d) failed", DEVICE_DATA->handle);
			} else {
				PRIVATE_DATA->current_position = (double)position;
			}

			if (FOCUSER_DIRECTION_MOVE_INWARD_ITEM->sw.value) {
				PRIVATE_DATA->target_position = PRIVATE_DATA->current_position - FOCUSER_STEPS_ITEM->number.value;
			} else {
				PRIVATE_DATA->target_position = PRIVATE_DATA->current_position + FOCUSER_STEPS_ITEM->number.value;
			}

			// Make sure we do not attempt to go beyond the limits
			if (FOCUSER_POSITION_ITEM->number.max < PRIVATE_DATA->target_position) {
				PRIVATE_DATA->target_position = FOCUSER_POSITION_ITEM->number.max;
			} else if (FOCUSER_POSITION_ITEM->number.min > PRIVATE_DATA->target_position) {
				PRIVATE_DATA->target_position = FOCUSER_POSITION_ITEM->number.min;
			}

			FOCUSER_POSITION_ITEM->number.value = PRIVATE_DATA->current_position;
			if (!dsd_goto_position(device, (uint32_t)PRIVATE_DATA->target_position)) {
				INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_goto_position(%d, %d) failed", DEVICE_DATA->handle, PRIVATE_DATA->target_position);
				FOCUSER_STEPS_PROPERTY->state = INDIGO_ALERT_STATE;
			}
			PRIVATE_DATA->focuser_timer = indigo_set_timer(device, 0.5, focuser_timer_callback);
		}
		indigo_update_property(device, FOCUSER_STEPS_PROPERTY, NULL);
		return INDIGO_OK;
	} else if (indigo_property_match(FOCUSER_ABORT_MOTION_PROPERTY, property)) {
		// -------------------------------------------------------------------------------- FOCUSER_ABORT_MOTION
		indigo_property_copy_values(FOCUSER_ABORT_MOTION_PROPERTY, property, false);
		FOCUSER_STEPS_PROPERTY->state = INDIGO_OK_STATE;
		FOCUSER_POSITION_PROPERTY->state = INDIGO_OK_STATE;
		FOCUSER_ABORT_MOTION_PROPERTY->state = INDIGO_OK_STATE;
		indigo_cancel_timer(device, &PRIVATE_DATA->focuser_timer);

		if (!dsd_stop(device)) {
			INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_stop(%d) failed", DEVICE_DATA->handle);
			FOCUSER_ABORT_MOTION_PROPERTY->state = INDIGO_ALERT_STATE;
		}
		uint32_t position;
		if (!dsd_get_position(device, &position)) {
			INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_get_position(%d) failed", DEVICE_DATA->handle);
			FOCUSER_ABORT_MOTION_PROPERTY->state = INDIGO_ALERT_STATE;
		} else {
			PRIVATE_DATA->current_position = (double)position;
		}
		FOCUSER_POSITION_ITEM->number.value = PRIVATE_DATA->current_position;
		FOCUSER_ABORT_MOTION_ITEM->sw.value = false;
		indigo_update_property(device, FOCUSER_POSITION_PROPERTY, NULL);
		indigo_update_property(device, FOCUSER_STEPS_PROPERTY, NULL);
		indigo_update_property(device, FOCUSER_ABORT_MOTION_PROPERTY, NULL);
		return INDIGO_OK;
	} else if (indigo_property_match(FOCUSER_COMPENSATION_PROPERTY, property)) {
		// -------------------------------------------------------------------------------- FOCUSER_COMPENSATION_PROPERTY
		indigo_property_copy_values(FOCUSER_COMPENSATION_PROPERTY, property, false);
		FOCUSER_COMPENSATION_PROPERTY->state = INDIGO_OK_STATE;
		if (IS_CONNECTED) {
			indigo_update_property(device, FOCUSER_COMPENSATION_PROPERTY, NULL);
		}
		return INDIGO_OK;
	} else if (indigo_property_match(DSD_STEP_MODE_PROPERTY, property)) {
		// -------------------------------------------------------------------------------- DSD_STEP_MODE_PROPERTY
		if (!IS_CONNECTED) return INDIGO_OK;
		indigo_property_copy_values(DSD_STEP_MODE_PROPERTY, property, false);
		DSD_STEP_MODE_PROPERTY->state = INDIGO_OK_STATE;
		stepmode_t mode;
		if(DSD_STEP_MODE_FULL_ITEM->sw.value) {
			mode = STEP_MODE_FULL;
		} else if(DSD_STEP_MODE_HALF_ITEM->sw.value) {
			mode = STEP_MODE_HALF;
		} else if(DSD_STEP_MODE_FOURTH_ITEM->sw.value) {
			mode = STEP_MODE_FOURTH;
		} else if(DSD_STEP_MODE_EIGTH_ITEM->sw.value) {
			mode = STEP_MODE_EIGTH;
		} else if(DSD_STEP_MODE_16TH_ITEM->sw.value) {
			mode = STEP_MODE_16TH;
		} else if(DSD_STEP_MODE_32TH_ITEM->sw.value) {
			mode = STEP_MODE_32TH;
		} else if(DSD_STEP_MODE_64TH_ITEM->sw.value) {
			mode = STEP_MODE_64TH;
		} else if(DSD_STEP_MODE_128TH_ITEM->sw.value) {
			mode = STEP_MODE_128TH;
		} else if(DSD_STEP_MODE_256TH_ITEM->sw.value) {
			mode = STEP_MODE_256TH;
		}
		if (!dsd_set_step_mode(device, mode)) {
			INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_set_step_mode(%d, %d) failed", DEVICE_DATA->handle, mode);
			DSD_STEP_MODE_PROPERTY->state = INDIGO_ALERT_STATE;
		}
		update_step_mode_switches(device);
		indigo_update_property(device, DSD_STEP_MODE_PROPERTY, NULL);
		return INDIGO_OK;
	} else if (indigo_property_match(DSD_CURRENT_CONTROL_PROPERTY, property)) {
		// -------------------------------------------------------------------------------- DSD_CURRENT_CONTROL_PROPERTY
		if (!IS_CONNECTED) return INDIGO_OK;
		indigo_property_copy_values(DSD_CURRENT_CONTROL_PROPERTY, property, false);
		DSD_CURRENT_CONTROL_PROPERTY->state = INDIGO_OK_STATE;

		uint32_t value;
		if (PRIVATE_DATA->focuser_version < 3) {
			if (!dsd_set_move_current(device, (uint32_t)DSD_CURRENT_CONTROL_MOVE_ITEM->number.target)) {
				INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_set_move_current(%d, %d) failed", DEVICE_DATA->handle, (uint32_t)DSD_CURRENT_CONTROL_MOVE_ITEM->number.target);
				DSD_CURRENT_CONTROL_PROPERTY->state = INDIGO_ALERT_STATE;
			}

			if (!dsd_set_hold_current(device, (uint32_t)DSD_CURRENT_CONTROL_HOLD_ITEM->number.target)) {
				INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_set_hold_current(%d, %d) failed", DEVICE_DATA->handle, (uint32_t)DSD_CURRENT_CONTROL_HOLD_ITEM->number.target);
				DSD_CURRENT_CONTROL_PROPERTY->state = INDIGO_ALERT_STATE;
			}

			if (!dsd_get_move_current(device, &value)) {
				INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_get_move_current(%d) failed", DEVICE_DATA->handle);
			} else {
				DSD_CURRENT_CONTROL_MOVE_ITEM->number.target = (double)value;
			}

			if (!dsd_get_hold_current(device, &value)) {
				INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_get_hold_current(%d) failed", DEVICE_DATA->handle);
				DSD_CURRENT_CONTROL_PROPERTY->state = INDIGO_ALERT_STATE;
			} else {
				DSD_CURRENT_CONTROL_HOLD_ITEM->number.target = (double)value;
			}
		} else {
			if (!dsd_set_move_current_multiplier(device, (uint32_t)DSD_CURRENT_CONTROL_MOVE_ITEM->number.target)) {
				INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_set_move_current_multiplier(%d, %d) failed", DEVICE_DATA->handle, (uint32_t)DSD_CURRENT_CONTROL_MOVE_ITEM->number.target);
				DSD_CURRENT_CONTROL_PROPERTY->state = INDIGO_ALERT_STATE;
			}

			if (!dsd_set_hold_current_multiplier(device, (uint32_t)DSD_CURRENT_CONTROL_HOLD_ITEM->number.target)) {
				INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_set_hold_current_multiplier(%d, %d) failed", DEVICE_DATA->handle, (uint32_t)DSD_CURRENT_CONTROL_HOLD_ITEM->number.target);
				DSD_CURRENT_CONTROL_PROPERTY->state = INDIGO_ALERT_STATE;
			}

			if (!dsd_get_move_current_multiplier(device, &value)) {
				INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_get_move_current_multiplier(%d) failed", DEVICE_DATA->handle);
			} else {
				DSD_CURRENT_CONTROL_MOVE_ITEM->number.target = (double)value;
			}

			if (!dsd_get_hold_current_multiplier(device, &value)) {
				INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_get_hold_current_multiplier(%d) failed", DEVICE_DATA->handle);
				DSD_CURRENT_CONTROL_PROPERTY->state = INDIGO_ALERT_STATE;
			} else {
				DSD_CURRENT_CONTROL_HOLD_ITEM->number.target = (double)value;
			}
		}

		indigo_update_property(device, DSD_CURRENT_CONTROL_PROPERTY, NULL);
		return INDIGO_OK;
	} else if (indigo_property_match(DSD_TIMINGS_PROPERTY, property)) {
		// -------------------------------------------------------------------------------- DSD_TIMINGS_PROPERTY
		if (!IS_CONNECTED) return INDIGO_OK;
		indigo_property_copy_values(DSD_TIMINGS_PROPERTY, property, false);
		DSD_TIMINGS_PROPERTY->state = INDIGO_OK_STATE;

		if (!dsd_set_settle_buffer(device, (uint32_t)DSD_TIMINGS_SETTLE_ITEM->number.target)) {
			INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_set_settle_buffer(%d, %d) failed", DEVICE_DATA->handle, (uint32_t)DSD_TIMINGS_SETTLE_ITEM->number.target);
			DSD_TIMINGS_PROPERTY->state = INDIGO_ALERT_STATE;
		}

		uint32_t value;
		if (!dsd_get_settle_buffer(device, &value)) {
			INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_get_settle_buffer(%d) failed", DEVICE_DATA->handle);
		} else {
			DSD_TIMINGS_SETTLE_ITEM->number.target = (double)value;
		}

		if (PRIVATE_DATA->focuser_version < 3) {
			if (!dsd_set_coils_timeout(device, (uint32_t)DSD_TIMINGS_COILS_TOUT_ITEM->number.target)) {
				INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_set_coils_timeout(%d, %d) failed", DEVICE_DATA->handle, (uint32_t)DSD_TIMINGS_COILS_TOUT_ITEM->number.target);
				DSD_TIMINGS_PROPERTY->state = INDIGO_ALERT_STATE;
			}

			if (!dsd_get_coils_timeout(device, &value)) {
				INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_get_coils_timeout(%d) failed", DEVICE_DATA->handle);
				DSD_TIMINGS_PROPERTY->state = INDIGO_ALERT_STATE;
			} else {
				DSD_TIMINGS_COILS_TOUT_ITEM->number.target = (double)value;
			}
		}

		indigo_update_property(device, DSD_TIMINGS_PROPERTY, NULL);
		return INDIGO_OK;
	} else if (indigo_property_match(DSD_COILS_MODE_PROPERTY, property)) {
		// -------------------------------------------------------------------------------- DSD_COILS_MODE_PROPERTY
		if (!IS_CONNECTED) return INDIGO_OK;
		indigo_property_copy_values(DSD_COILS_MODE_PROPERTY, property, false);
		DSD_COILS_MODE_PROPERTY->state = INDIGO_OK_STATE;
		coilsmode_t mode;
		if(DSD_COILS_MODE_IDLE_OFF_ITEM->sw.value) {
			mode = COILS_MODE_IDLE_OFF;
		} else if(DSD_COILS_MODE_ALWAYS_ON_ITEM->sw.value) {
			mode = COILS_MODE_ALWAYS_ON;
		} else if(DSD_COILS_MODE_TIMEOUT_ITEM->sw.value) {
			mode = COILS_MODE_IDLE_TIMEOUT;
		}
		if (!dsd_set_coils_mode(device, mode)) {
			INDIGO_DRIVER_ERROR(DRIVER_NAME, "dsd_set_coils_mode(%d, %d) failed", DEVICE_DATA->handle, mode);
			DSD_COILS_MODE_PROPERTY->state = INDIGO_ALERT_STATE;
		}
		update_coils_mode_switches(device);
		indigo_update_property(device, DSD_COILS_MODE_PROPERTY, NULL);
		return INDIGO_OK;
		// -------------------------------------------------------------------------------- FOCUSER_MODE
	} else if (indigo_property_match(FOCUSER_MODE_PROPERTY, property)) {
		indigo_property_copy_values(FOCUSER_MODE_PROPERTY, property, false);
		if (FOCUSER_MODE_MANUAL_ITEM->sw.value) {
			indigo_define_property(device, FOCUSER_ON_POSITION_SET_PROPERTY, NULL);
			indigo_define_property(device, FOCUSER_SPEED_PROPERTY, NULL);
			indigo_define_property(device, FOCUSER_REVERSE_MOTION_PROPERTY, NULL);
			indigo_define_property(device, FOCUSER_DIRECTION_PROPERTY, NULL);
			indigo_define_property(device, FOCUSER_STEPS_PROPERTY, NULL);
			indigo_define_property(device, FOCUSER_ABORT_MOTION_PROPERTY, NULL);
			indigo_define_property(device, FOCUSER_BACKLASH_PROPERTY, NULL);
			indigo_delete_property(device, FOCUSER_POSITION_PROPERTY, NULL);
			FOCUSER_POSITION_PROPERTY->perm = INDIGO_RW_PERM;
			indigo_define_property(device, FOCUSER_POSITION_PROPERTY, NULL);
		} else {
			indigo_delete_property(device, FOCUSER_ON_POSITION_SET_PROPERTY, NULL);
			indigo_delete_property(device, FOCUSER_SPEED_PROPERTY, NULL);
			indigo_delete_property(device, FOCUSER_REVERSE_MOTION_PROPERTY, NULL);
			indigo_delete_property(device, FOCUSER_DIRECTION_PROPERTY, NULL);
			indigo_delete_property(device, FOCUSER_STEPS_PROPERTY, NULL);
			indigo_delete_property(device, FOCUSER_ABORT_MOTION_PROPERTY, NULL);
			indigo_delete_property(device, FOCUSER_BACKLASH_PROPERTY, NULL);
			indigo_delete_property(device, FOCUSER_POSITION_PROPERTY, NULL);
			FOCUSER_POSITION_PROPERTY->perm = INDIGO_RO_PERM;
			indigo_define_property(device, FOCUSER_POSITION_PROPERTY, NULL);
		}
		FOCUSER_MODE_PROPERTY->state = INDIGO_OK_STATE;
		indigo_update_property(device, FOCUSER_MODE_PROPERTY, NULL);
		return INDIGO_OK;
	} else if (indigo_property_match(CONFIG_PROPERTY, property)) {
		// -------------------------------------------------------------------------------- CONFIG
		if (indigo_switch_match(CONFIG_SAVE_ITEM, property)) {
			indigo_save_property(device, NULL, LA_MODEL_HINT_PROPERTY);
			indigo_save_property(device, NULL, DSD_STEP_MODE_PROPERTY);
			indigo_save_property(device, NULL, DSD_COILS_MODE_PROPERTY);
			indigo_save_property(device, NULL, DSD_CURRENT_CONTROL_PROPERTY);
			indigo_save_property(device, NULL, DSD_TIMINGS_PROPERTY);
		}
		// --------------------------------------------------------------------------------
	}
	return indigo_focuser_change_property(device, client, property);
}


static indigo_result focuser_detach(indigo_device *device) {
	assert(device != NULL);
	indigo_device_disconnect(NULL, device->name);
	indigo_release_property(DSD_STEP_MODE_PROPERTY);
	indigo_release_property(DSD_COILS_MODE_PROPERTY);
	indigo_release_property(DSD_CURRENT_CONTROL_PROPERTY);
	indigo_release_property(DSD_TIMINGS_PROPERTY);
	indigo_global_unlock(device);
	INDIGO_DEVICE_DETACH_LOG(DRIVER_NAME, device->name);

	indigo_delete_property(device, LA_MODEL_HINT_PROPERTY, NULL);
	indigo_release_property(LA_MODEL_HINT_PROPERTY);
	return indigo_focuser_detach(device);
}


// --------------------------------------------------------------------------------

static int device_number = 0;


static void create_device(int device_index, int port_index, char *name_ext) {
	static indigo_device focuser_template = INDIGO_DEVICE_INITIALIZER(
		FOCUSER_LUNATICO_NAME,
		focuser_attach,
		dsd_enumerate_properties,
		focuser_change_property,
		NULL,
		focuser_detach
	);

	if (port_index >= MAX_PORTS) return;
	if (device_data[device_index].port[port_index] != NULL) return;

	device_data[device_index].private_data[port_index] = malloc(sizeof(lunatico_private_data));
	assert(device_data[device_index].private_data[port_index] != NULL);
	memset(device_data[device_index].private_data[port_index], 0, sizeof(lunatico_private_data));
	device_data[device_index].private_data[port_index]->handle = -1;
	device_data[device_index].private_data[port_index]->port_index = port_index;
	device_data[device_index].private_data[port_index]->shared_data = (void *)&device_data[device_index];

	device_data[device_index].port[port_index] = malloc(sizeof(indigo_device));
	assert(device_data[device_index].port[port_index] != NULL);
	memcpy(device_data[device_index].port[port_index], &focuser_template, sizeof(indigo_device));
	device_data[device_index].port[port_index]->private_data = device_data[device_index].private_data[port_index];
	sprintf(device_data[device_index].port[port_index]->name, "%s (%s)", FOCUSER_LUNATICO_NAME, name_ext);
	indigo_attach_device(device_data[device_index].port[port_index]);
}


static void delete_device(int device_index, int port_index) {
	if (port_index >= MAX_PORTS) return;

	if (device_data[device_index].port[port_index] != NULL) {
		indigo_detach_device(device_data[device_index].port[port_index]);
		free(device_data[device_index].port[port_index]);
		device_data[device_index].port[port_index] = NULL;
	}
	if (device_data[device_index].private_data[port_index] != NULL) {
		free(device_data[device_index].private_data[port_index]);
		device_data[device_index].private_data[port_index] = NULL;
	}
	memset(&device_data[device_index], 0, sizeof(lunatico_device_data));
}


indigo_result DRIVER_ENTRY_POINT(indigo_driver_action action, indigo_driver_info *info) {

	static indigo_driver_action last_action = INDIGO_DRIVER_SHUTDOWN;

	SET_DRIVER_INFO(info, "Lunatico Astronomia Focuser", __FUNCTION__, DRIVER_VERSION, false, last_action);

	if (action == last_action)
		return INDIGO_OK;

	switch (action) {
	case INDIGO_DRIVER_INIT:
		last_action = action;

		create_device(0, device_number, "Main");
		device_number++;
		create_device(0, device_number, "Ext");
		device_number++;
		break;

	case INDIGO_DRIVER_SHUTDOWN:
		last_action = action;
		for (int index = 0; index < device_number; index++) {
			delete_device(0, index);
		}
		break;

	case INDIGO_DRIVER_INFO:
		break;
	}

	return INDIGO_OK;
}
