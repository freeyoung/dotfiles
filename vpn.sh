#!/bin/bash

route add -net 118.144.67.0/24 10.0.0.100
route delete default
route add default 10.8.10.209
