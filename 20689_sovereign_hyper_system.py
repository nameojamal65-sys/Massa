import React, { useEffect, useState } from 'react';
import './App.css';

function App() {
  const [status, setStatus] = useState({});
  
  const fetchStatus = async () => {
    const res = await fetch('/status');
    const data = await res.json();
    setStatus(data);
  };
  
  const handleAction = async (component, action) => {
    await fetch(`/${action}/${component}`, { method: 'POST' });
    fetchStatus();
  };
  
  const rebuildSystem = async () => {
    await fetch('/rebuild_system', { method: 'POST' });
  };
  
  useEffect(() => { fetchStatus(); }, []);
  
  return (
    <div className="App">
      <h1>🚀 Sovereign Hyper System</h1>
      <button onClick={rebuildSystem} style={{background:'red', color:'white', padding:'10px', margin:'10px'}}>Rebuild System (AI)</button>
      <div className="components">
        {Object.keys(status).map(comp => (
          <div key={comp} style={{margin:'10px', padding:'10px', border:'1px solid black'}}>
            <h3>{comp}</h3>
            <p>Status: {status[comp]}</p>
            <button onClick={()=>handleAction(comp,'start')}>Start</button>
            <button onClick={()=>handleAction(comp,'stop')}>Stop</button>
          </div>
        ))}
      </div>
    </div>
  );
}

export default App;
