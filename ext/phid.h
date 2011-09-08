/* 
 * File:   phid.h
 * Author: daniel
 *
 * Created on August 15, 2008, 5:13 PM
 */

#include <stdio.h>
#include <phidget21.h>
#include <sqlite3.h>

CPhidgetRFIDHandle rfid = 0;

sqlite3 *db;
char *zErrMsg = 0;
int rc;
char last_tag[25];
int tags=0;

CPhidgetLog_level level = PHIDGET_LOG_VERBOSE;

void enable_loggin(char *outputFile) {
	CPhidget_enableLogging(level, outputFile);
}

void disable_loggin() {
	CPhidget_disableLogging();
}

void log_message(char* id, char* message) {
	CPhidget_log(level, id, message);
}

const char* get_device_name() {
	const char *name;
	CPhidget_getDeviceName((CPhidgetHandle) rfid, &name);
	return name;
}

const char* get_device_type() {
	const char *name;
	CPhidget_getDeviceType((CPhidgetHandle) rfid, &name);
	return name;
}

int get_serial_number() {
	int serialNo;
	CPhidget_getSerialNumber((CPhidgetHandle) rfid, &serialNo);
	return serialNo;
}

int get_device_version() {
	int version;
	CPhidget_getDeviceVersion((CPhidgetHandle) rfid, &version);
	return version;
}

void turn_led_on() {
	CPhidgetRFID_setLEDOn(rfid, 1);
}

void turn_led_off() {
	CPhidgetRFID_setLEDOn(rfid, 0);
}

static int callback(void *NotUsed, int argc, char **argv, char **azColName){
	int i;
	for(i=0; i<argc; i++){
		printf("%s = %s\n", azColName[i], argv[i] ? argv[i] : "NULL");
	}
	printf("\n");
	return 0;
}

int tag_handler(CPhidgetRFIDHandle RFID, void *usrptr, unsigned char *TagVal) {
	turn_led_on();
	
	char id[255];
	//char message[25];
	char sql[512];
	
	tags++;	

	sprintf(id, "Reader Serial:%d", get_serial_number());
	sprintf(last_tag, "Tag Read:%02x%02x%02x%02x%02x", TagVal[0], TagVal[1], TagVal[2], TagVal[3], TagVal[4]);
	sprintf(sql, "INSERT INTO log VALUES('%d','%02x%02x%02x%02x%02x',DATETIME('now'));", get_serial_number(), TagVal[0], TagVal[1], TagVal[2], TagVal[3], TagVal[4]);
	
	printf("%s\n", last_tag);
	
	log_message(id, last_tag);
	rc = sqlite3_exec(db, sql, callback, 0, &zErrMsg);
	return 0;
}

int tag_lost_handler(CPhidgetRFIDHandle RFID, void *usrptr, unsigned char *TagVal) {
	turn_led_off();
	
	char id[255];
	//char message[25];
	char sql[512];
	
	tags++;	
	
	sprintf(id, "Reader Serial:%d", get_serial_number());
	sprintf(last_tag, "Tag Lost:%02x%02x%02x%02x%02x", TagVal[0], TagVal[1], TagVal[2], TagVal[3], TagVal[4]);
	
	printf("%s\n", last_tag);
	
	log_message(id, last_tag);
	return 0;
}

void turn_antenna_on() {
	CPhidgetRFID_setAntennaOn(rfid, 1);
	CPhidgetRFID_set_OnTag_Handler(rfid, tag_handler, NULL);
	CPhidgetRFID_set_OnTagLost_Handler(rfid, tag_lost_handler, NULL);
}

void turn_antenna_off() {
	CPhidgetRFID_setAntennaOn(rfid, 0);
}

void rfid_create(char *dbname) {
	tags=0;
	CPhidgetRFID_create(&rfid);
	CPhidget_open((CPhidgetHandle)rfid, -1);
	rc = sqlite3_open(dbname, &db);
	rc = sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS log (reader_id TEXT NOT NULL, tag_read_id TEXT NOT NULL, read_at DATETIME NOT NULL, PRIMARY KEY (reader_id, tag_read_id, read_at));", callback, 0, &zErrMsg);
}

void rfid_delete() {
	CPhidget_close((CPhidgetHandle)rfid);
	CPhidget_delete((CPhidgetHandle)rfid);
	disable_loggin();
	sqlite3_close(db);
}

int wait_attachment(int time) {
	int result = CPhidget_waitForAttachment((CPhidgetHandle)rfid, time);
	return result;
}

const char* get_error_description(int result) {
	const char *err;
	CPhidget_getErrorDescription(result, &err);
	return err;
}

char* get_lastTag(){
	return last_tag;
}

int count_tags(){
	return tags;
}

