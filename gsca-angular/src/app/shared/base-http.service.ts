import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../environments/environment';

@Injectable()
export class BaseHttpService {
  constructor(private http: HttpClient) {}

  public getData(route: string, data?: any): Observable<any> {
    return this.http.get(this.generateRoute(route, environment.apiURL), this.generateOptions(data));
  }

  public postData(route: string, data: any): Observable<any> {
    return this.http.post(this.generateRoute(route, environment.apiURL), data, { headers: { 'content-type': 'application/json' } });
  }

  public getDataImage(route: string, data?: any): Observable<any> {
    return this.http.get(this.generateRoute(route, environment.apiURL), { responseType: 'blob' });
  }

  public postDataImage(route: string, data: any): Observable<any> {
    return this.http.post(this.generateRoute(route, environment.apiURL), data, {
      headers: { 'content-type': 'application/json' },
      responseType: 'blob',
    });
  }

  public generateRoute(route: string, envURL = environment.apiURL): string {
    return `${envURL}/${route}`;
  }

  public generateOptions(data?: any): any {
    return { params: data };
  }
}
