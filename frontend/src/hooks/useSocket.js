import { useEffect, useRef } from 'react';
import { io } from 'socket.io-client';

export function useSocket(handlers) {
  const socketRef = useRef(null);

  useEffect(() => {
    const token = localStorage.getItem('edara_token');
    if (!token) return;
    const socket = io({
      auth: { token },
      transports: ['websocket', 'polling']
    });
    socketRef.current = socket;

    Object.entries(handlers || {}).forEach(([event, fn]) => {
      socket.on(event, fn);
    });

    return () => {
      socket.disconnect();
      socketRef.current = null;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return socketRef;
}
