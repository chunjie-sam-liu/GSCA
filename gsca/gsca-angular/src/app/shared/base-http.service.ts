import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../environments/environment';

@Injectable()
export class BaseHttpService {
  constructor(private http: HttpClient) {}

  public getData(route: string, data?: any): Observable<any> {
    return this.http.get(this._generateRoute(route, environment.apiURL), this._generateOptions(data));
  }

  public postData(route: string, data?: any): Observable<any> {
    return this.http.post(this._generateRoute(route, environment.apiURL), data, { headers: { 'content-type': 'application/json' } });
  }

  private _generateRoute(route: string, envURL: string): string {
    return `${envURL}/${route}`;
  }

  private _generateOptions(data?: any): any {
    return { params: data };
  }
}
