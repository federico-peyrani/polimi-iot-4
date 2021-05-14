# Polimi IoT: Challenge 04
## TinyOS ack-based sensor reading

### Deploy and run with Docker

Clone the repository and run the docker command to instantly build the source code and run the simulation. The output log will be saved in `output/simulation.txt`.

```
git clone https://github.com/federico-peyrani/polimi-iot-4
cd polimi-iot-4
docker run --rm -it -v $(pwd):/code -w /code gmbilla/tinyos sh -c "make micaz sim && python RunSimulationScript.py"
```
