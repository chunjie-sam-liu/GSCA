import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { MrnaComponent } from './mrna.component';

describe('MrnaComponent', () => {
  let component: MrnaComponent;
  let fixture: ComponentFixture<MrnaComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ MrnaComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(MrnaComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
