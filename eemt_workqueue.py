from work_queue import *

def init_workqueue(proj_dir,port,name):
    try:
        print "Port: %d" % port
        wq = WorkQueue(port)
        wq.specify_name(name)
        print "Work queue started with project name " + wq.name
    except:
        print "Failed to start Work Queue"
    return wq
def create_tasks_eemt(wq, proj_dir):
    #Need to run r.sun for everyday of year
    days=list(range(1,366))
    wq, tasks_sun = rsun_tasks(wq, proj_dir, days)
    #Then do mapcalcs
    return wq, tasks_sun
def create_tasks_eemt_topo(wq, proj_dir):
    #Need to run r.sun for each MONTH
    days=[17,47,75,105,135,162,198,228,258,288,318,344]
    wq, tasks = rsun_tasks(wq, proj_dir, days)
    #Then do mapcalcs for Topo
    return wq, tasks
def rsun_tasks(wq,proj_dir,days):
    #Input file: 10m DEM (pit), Rsun script
    dem = proj_dir+"/pit_converted.tif"
    rsun = proj_dir+"/rsun.sh"
    tasks=0
    for day in days:
    ##--Set up paths
        slope=proj_dir+"/slope.tif"
        aspect=proj_dir+"/aspect.tif"
        total_sun=proj_dir+"/total_sun_day_%d.tif" % day
        hours_sun=proj_dir+"/hours_sun_day_%d.tif" % day
        flat_sun=proj_dir+"/flat_sun.tif"
    ##--Rsun command
        command="./rsun.sh dem.tif %d" % day
    ##--Create WorkQueue Task
        task = Task(command)
    ##--Set input files
        task.specify_input_file(dem, "dem.tif", cache=True)
        task.specify_input_file(rsun,"rsun.sh", cache=True)
    ##--Set Output Files
        task.specify_output_file(slope,'slope.tif', cache=False)
        task.specify_output_file(aspect,'aspect.tif',cache=False)
        task.specify_output_file(total_sun, 'total_sun_day_%d.tif' % day, cache=True)
        task.specify_output_file(hours_sun, 'hours_sun_day_%d.tif' % day, cache=True)
        task.specify_output_file(flat_sun, 'flat_sun.tif', cache=True)
    ##--Submit task
        taskId = wq.submit(task)
        tasks+=1
    return wq,tasks
def eemt_calc():
    
    return
def eemt_topo_calc():
    
    return
def run(wq,total):
    completed=0
    while not wq.empty():
        t = wq.wait(5)
        
        if t:
            if t.return_status == 0:
                completed += 1
                print "Task %d of %d finished" % (completed, total)
            else:
                print "Task %d failed" % t.id
                print t.output
    wq.shutdown_workers(0)
    return