CREATE OR REPLACE PACKAGE pkRecompilation AS
        PROCEDURE Compile_Object (aObjectName VARCHAR2, aForced BOOLEAN);
        PROCEDURE Compile_All (aForced BOOLEAN);
END;
/
SHOW ERRORS;

CREATE OR REPLACE PACKAGE BODY pkRecompilation AS

FUNCTION GetObjectValidity (aObjectName VARCHAR2) RETURN BOOLEAN AS

/*
| Returns if an object is valid or not. for packages, the validity of BOTH
specification and body
| are tested: cValidity cursor will contain 2 rows, one for the
specification, and one for the body
*/

        cursor cValidity (pObjectName VARCHAR2) IS
                SELECT STATUS FROM USER_OBJECTS WHERE UPPER(OBJECT_NAME) =
UPPER(pObjectName);
        Result BOOLEAN;

BEGIN
        Result := TRUE;
        FOR rValidity IN cValidity (aObjectName) LOOP
                Result := Result AND rValidity.STATUS = 'VALID';
        END LOOP;
        RETURN Result;
END;

/*****************************************************************************/

FUNCTION GetObjectType (aObjectName VARCHAR2) RETURN VARCHAR2 AS

/*
| Returns the description for the type of the object : PROCEDURE, TABLE, ...
| An error is raised if the object doesn't exist
*/

        cursor cObjectType (pObjectName VARCHAR2) IS
                SELECT OBJECT_TYPE FROM USER_OBJECTS WHERE
UPPER(OBJECT_NAME) = UPPER(pObjectName);
        rObjectType cObjectType%ROWTYPE;
BEGIN

        OPEN cObjectType (aObjectName);

        FETCH cObjectType INTO rObjectType;

        IF cObjectType%NOTFOUND THEN
                RAISE_APPLICATION_ERROR (-20001, 'Object Does not exist');
        ELSE
                RETURN rObjectType.OBJECT_TYPE;
        END IF;

        CLOSE cObjectType;

EXCEPTION
        WHEN OTHERS THEN
                IF cObjectType%ISOPEN THEN
                        CLOSE cObjectType;
                END IF;
                RAISE;

END;

/*****************************************************************************/

PROCEDURE Compile_Object (aObjectName VARCHAR2, aForced BOOLEAN) AS

/*
| Compiles an object if it's invalid (or forced)
| Compiles before the objects it's dependent on IN THE SAME SHEMA (objects
of other owners won't be compiled)
*/

        CURSOR cDependencies (pObjectName VARCHAR2) IS
                SELECT OBJECT_NAME, STATUS FROM USER_OBJECTS WHERE
                OBJECT_NAME IN  (select DISTINCT REFERENCED_NAME 
                		from user_dependencies WHERE UPPER(NAME) = UPPER(pObjectName))
                AND STATUS = 'INVALID';
        cRecompile INTEGER;

BEGIN

        -- Compiles only if not valid
        IF (GetObjectValidity(aObjectName) = FALSE) OR (aForced = TRUE) THEN
                -- Compiles first objects aObjectName is dependent on
                FOR rDependency IN cDependencies (aObjectName) LOOP
                        Compile_Object (rDependency.OBJECT_NAME, aForced);
                END LOOP;

                -- Then compiles object itself
                cRecompile := DBMS_SQL.OPEN_CURSOR;
                DBMS_SQL.PARSE (cRecompile, 'ALTER ' ||	GetObjectType(aObjectName) || ' ' || aObjectName || ' COMPILE',DBMS_SQL.NATIVE);
                DBMS_SQL.CLOSE_CURSOR (cRecompile);

        END IF;

EXCEPTION
        WHEN OTHERS THEN
                IF cDependencies%ISOPEN THEN
                        CLOSE cDependencies;
                END IF;
                RAISE;
END;

/*****************************************************************************/

PROCEDURE Compile_All (aForced BOOLEAN) as
        cursor cObjectNames IS
                SELECT OBJECT_NAME FROM USER_OBJECTS
                WHERE STATUS = 'INVALID' AND
                (
                OBJECT_TYPE = 'FUNCTION' OR
                OBJECT_TYPE = 'PROCEDURE' OR
                OBJECT_TYPE = 'PACKAGE' OR
                OBJECT_TYPE = 'PACKAGE BODY'
                );
BEGIN
        FOR rObjectName IN cObjectNames LOOP
                COMPILE_OBJECT (rObjectName.OBJECT_NAME, aForced);
        END LOOP;

EXCEPTION
        WHEN OTHERS THEN
                IF cObjectNames%ISOPEN THEN
                        CLOSE cObjectNames;
                END IF;
                RAISE;
END;

END;
/
SHOW ERRORS;
